# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Deployment::Configurations::Kind do
  subject(:configuration) do
    described_class.new(
      namespace: "gitlab",
      ci: true,
      gitlab_domain: "127.0.0.1.nip.io",
      admin_password: "password",
      admin_token: "token",
      host_http_port: 80,
      host_ssh_port: 22,
      host_registry_port: 5000
    )
  end

  let(:kubeclient) { instance_double(Gitlab::Cng::Kubectl::Client, create_resource: "", execute: "", patch: "") }
  let(:port_mappings) do
    {
      80 => 32080,
      22 => 32222,
      5000 => 32495
    }
  end

  before do
    allow(Gitlab::Cng::Kind::Cluster).to receive(:host_port_mapping).and_return(port_mappings[22])
    allow(Gitlab::Cng::Kind::Cluster).to receive(:host_port_mapping).with(80).and_return(port_mappings[80])
    allow(Gitlab::Cng::Kind::Cluster).to receive(:host_port_mapping).with(5000).and_return(port_mappings[5000])
    allow(Gitlab::Cng::Kubectl::Client).to receive(:new).and_return(kubeclient)
  end

  it "runs pre-deployment setup", :aggregate_failures do
    expect { configuration.run_pre_deployment_setup }.to output(/Creating admin user initial password secret/).to_stdout

    expect(kubeclient).to have_received(:create_resource).with(
      Gitlab::Cng::Kubectl::Resources::Secret.new("gitlab-initial-root-password", "password", "password")
    )
    expect(kubeclient).to have_received(:create_resource).with(
      Gitlab::Cng::Kubectl::Resources::Configmap.new(
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
        }
      },
      "nginx-ingress": {
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
    })
  end

  it "returns correct gitlab url" do
    expect(configuration.gitlab_url).to eq("http://gitlab.127.0.0.1.nip.io")
  end

  it "handles already existing admin PAT" do
    allow(kubeclient).to receive(:patch)
    allow(kubeclient).to receive(:execute)
      .with("toolbox", kind_of(Array), container: "toolbox")
      .and_raise(Gitlab::Cng::Kubectl::Client::Error, <<~MSG)
        /srv/gitlab/vendor/bundle/ruby/3.1.0/gems/activerecord-7.0.8.1/lib/active_record/connection_adapters/postgresql_adapter.rb:768:in `exec_params': PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint "index_personal_access_tokens_on_token_digest" (ActiveRecord::RecordNotUnique)
      MSG

    expect { configuration.run_post_deployment_setup }.to output(/Token already exists, skipping!/).to_stdout
  end
end
