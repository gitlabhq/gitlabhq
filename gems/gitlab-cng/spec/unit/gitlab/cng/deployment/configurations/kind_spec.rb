# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Deployment::Configurations::Kind do
  subject(:configuration) { described_class.new("gitlab", kubeclient, true, "127.0.0.1.nip.io") }

  let(:kubeclient) { instance_double(Gitlab::Cng::Kubectl::Client, create_resource: "", execute: "") }

  let(:env) do
    {
      "GITLAB_ADMIN_PASSWORD" => "password",
      "GITLAB_ADMIN_ACCESS_TOKEN" => "token"
    }
  end

  around do |example|
    ClimateControl.modify(env) { example.run }
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
    expect { configuration.run_post_deployment_setup }.to output(/Creating admin user personal access token/).to_stdout

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
              "gitlab-shell": 32022,
              http: 32080
            }
          }
        }
      }
    })
  end

  it "returns correct gitlab url" do
    expect(configuration.gitlab_url).to eq("http://gitlab.127.0.0.1.nip.io")
  end
end
