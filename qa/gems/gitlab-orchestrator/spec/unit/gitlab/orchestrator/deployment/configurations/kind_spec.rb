# frozen_string_literal: true

RSpec.describe Gitlab::Orchestrator::Deployment::Configurations::Kind do
  subject(:configuration) do
    described_class.new(
      namespace: "gitlab",
      ci: true,
      gitlab_domain: "127.0.0.1.nip.io",
      admin_password: "password",
      admin_token: "token",
      host_http_port: 80,
      host_ssh_port: 22,
      host_registry_port: 5000,
      resource_preset: resource_preset
    )
  end

  let(:resource_preset) { "default" }

  let(:kubeclient) do
    instance_double(Gitlab::Orchestrator::Kubectl::Client, create_resource: "", execute: "", patch: "")
  end

  let(:helmclient) do
    instance_double(Gitlab::Orchestrator::Helm::Client, add_helm_chart: nil, upgrade: nil, uninstall: nil)
  end

  let(:valkey) do
    instance_double(
      Gitlab::Orchestrator::Deployment::Services::Valkey,
      install: nil,
      host: "valkey.gitlab.svc.cluster.local",
      auth_secret_name: "valkey-auth",
      auth_secret_key: "default"
    )
  end

  let(:cnpg) do
    instance_double(
      Gitlab::Orchestrator::Deployment::Services::CloudNativePG,
      install: nil,
      host: "cnpg-rw.gitlab.svc.cluster.local",
      password_secret_name: "cnpg-app",
      password_secret_key: "password"
    )
  end

  let(:garage) do
    instance_double(
      Gitlab::Orchestrator::Deployment::Services::Garage,
      install: nil,
      object_storage_secret_name: "garage-gitlab-object-storage",
      s3cmd_secret_name: "garage-gitlab-object-storage-s3cmd",
      registry_storage_secret_name: "garage-gitlab-registry-storage"
    )
  end

  let(:port_mappings) do
    {
      80 => 32080,
      22 => 32222,
      5000 => 32495
    }
  end

  before do
    allow(Gitlab::Orchestrator::Kind::Cluster).to receive(:host_port_mapping).and_return(port_mappings[22])
    allow(Gitlab::Orchestrator::Kind::Cluster).to receive(:host_port_mapping).with(80).and_return(port_mappings[80])
    allow(Gitlab::Orchestrator::Kind::Cluster).to receive(:host_port_mapping).with(5000).and_return(port_mappings[5000])
    allow(Gitlab::Orchestrator::Kubectl::Client).to receive(:new).and_return(kubeclient)
    allow(Gitlab::Orchestrator::Helm::Client).to receive(:new).and_return(helmclient)
    allow(Gitlab::Orchestrator::Deployment::Services::Valkey).to receive(:new).and_return(valkey)
    allow(Gitlab::Orchestrator::Deployment::Services::CloudNativePG).to receive(:new).and_return(cnpg)
    allow(Gitlab::Orchestrator::Deployment::Services::Garage).to receive(:new).and_return(garage)
  end

  it "runs pre-deployment setup", :aggregate_failures do
    expect { configuration.run_pre_deployment_setup }.to output(
      /Installing external services.*Creating admin user initial password secret/m
    ).to_stdout

    expect(valkey).to have_received(:install)
    expect(cnpg).to have_received(:install)
    expect(garage).to have_received(:install)
    expect(kubeclient).to have_received(:create_resource).with(
      Gitlab::Orchestrator::Kubectl::Resources::Secret.new("gitlab-initial-root-password", "password", "password")
    )
    expect(kubeclient).to have_received(:create_resource).with(
      Gitlab::Orchestrator::Kubectl::Resources::Configmap.new(
        "pre-receive-hook",
        "hook.sh",
        <<~SH
            #!/usr/bin/env bash

            if [[ $GL_PROJECT_PATH =~ 'reject-prereceive' ]]; then
              echo 'GL-HOOK-ERR: Custom error message rejecting prereceive hook for projects with GL_PROJECT_PATH matching pattern reject-prereceive'
              exit 1
            fi
        SH
      ))
  end

  it "runs post-deployment setup", :aggregate_failures do
    allow(kubeclient).to receive_messages(
      patch: "",
      execute: ""
    )
    expect(kubeclient).to receive(:patch).with(
      'svc',
      'gitlab-registry',
      {
        spec: {
          type: 'NodePort',
          ports: [
            {
              name: 'registry',
              port: 5000,
              targetPort: 5000,
              protocol: 'TCP',
              nodePort: 32495
            }
          ]
        }
      }.to_json
    ).ordered

    expect do
      configuration.run_post_deployment_setup
    end.to output(/Creating admin user personal access token/).to_stdout

    expect(kubeclient).to have_received(:execute).with(
      "toolbox",
      [
        "gitlab-rails",
        "runner",
        <<~RUBY
            Gitlab::Seeder.quiet do
              User.find_by(username: 'root').tap do |user|
                params = {
                  scopes: Gitlab::Auth.all_available_scopes.map(&:to_s),
                  name: 'seeded-api-token'
                }

                user.personal_access_tokens.build(params).tap do |pat|
                  pat.expires_at = 365.days.from_now
                  pat.set_token("token")
                  pat.organization = Organizations::Organization.default_organization
                  pat.save!
                end
              end
            end
        RUBY
      ],
      container: "toolbox"
    )
  end

  it "returns configuration specific values" do
    # values depends on external services being installed first
    expect { configuration.run_pre_deployment_setup }.to output.to_stdout

    expect(configuration.values).to eq({
      global: {
        shell: {
          port: 22
        },
        pages: {
          port: 80
        },
        registry: {
          port: 5000
        },
        initialRootPassword: {
          secret: "gitlab-initial-root-password"
        },
        gitaly: {
          hooks: {
            preReceive: {
              configmap: "pre-receive-hook"
            }
          }
        },
        ingress: {
          enabled: true,
          configureCertmanager: false,
          tls: { enabled: false }
        },
        minio: { enabled: false },
        gatewayApi: { enabled: false, configureCertmanager: false, installEnvoy: false },
        psql: {
          host: "cnpg-rw.gitlab.svc.cluster.local",
          password: {
            secret: "cnpg-app",
            key: "password"
          }
        },
        redis: {
          host: "valkey.gitlab.svc.cluster.local",
          auth: {
            secret: "valkey-auth",
            key: "default"
          }
        },
        appConfig: {
          object_store: {
            enabled: true,
            proxy_download: true,
            connection: {
              secret: "garage-gitlab-object-storage",
              key: "config"
            }
          },
          artifacts: { bucket: "gitlab-artifacts" },
          lfs: { bucket: "git-lfs" },
          uploads: { bucket: "gitlab-uploads" },
          packages: { bucket: "gitlab-packages" },
          externalDiffs: { enabled: true, bucket: "gitlab-mr-diffs" },
          terraformState: { enabled: true, bucket: "gitlab-terraform-state" },
          ciSecureFiles: { enabled: true, bucket: "gitlab-ci-secure-files" },
          dependencyProxy: { enabled: true, bucket: "gitlab-dependency-proxy" }
        }
      },
      gitlab: {
        toolbox: {
          backups: {
            objectStorage: {
              config: {
                secret: "garage-gitlab-object-storage-s3cmd",
                key: "config"
              }
            }
          }
        }
      },
      registry: {
        storage: {
          secret: "garage-gitlab-registry-storage",
          key: "config",
          redirect: { disable: true }
        }
      },
      certmanager: { install: false },
      "nginx-ingress": {
        enabled: true,
        controller: {
          replicaCount: 1,
          minAavailable: 1,
          service: {
            type: "NodePort",
            nodePorts: {
              "gitlab-shell": port_mappings[22],
              http: port_mappings[80],
              registry: port_mappings[5000]
            }
          }
        }
      }
    }.deep_merge(Gitlab::Orchestrator::Deployment::ResourcePresets.resource_values(resource_preset)))
  end

  it "returns correct gitlab url" do
    expect(configuration.gitlab_url).to eq("http://gitlab.127.0.0.1.nip.io")
  end

  it "handles already existing admin PAT" do
    allow(kubeclient).to receive(:patch)
    allow(kubeclient).to receive(:execute)
      .with("toolbox", kind_of(Array), container: "toolbox")
      .and_raise(Gitlab::Orchestrator::Kubectl::Client::Error, <<~MSG)
        /srv/gitlab/vendor/bundle/ruby/3.1.0/gems/activerecord-7.0.8.1/lib/active_record/connection_adapters/postgresql_adapter.rb:768:in `exec_params': PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint "index_personal_access_tokens_on_token_digest" (ActiveRecord::RecordNotUnique)
      MSG

    expect { configuration.run_post_deployment_setup }.to output(/Token already exists, skipping!/).to_stdout
  end
end
