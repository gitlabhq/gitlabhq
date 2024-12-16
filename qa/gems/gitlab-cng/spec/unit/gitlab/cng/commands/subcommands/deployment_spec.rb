# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Commands::Subcommands::Deployment do
  include_context "with command testing helper"

  describe "kind deployment command" do
    let(:command_name) { "kind" }

    let(:installation_instance) { instance_double(Gitlab::Cng::Deployment::Installation, create: nil) }
    let(:configuration_instance) { instance_double(Gitlab::Cng::Deployment::Configurations::Kind) }
    let(:cluster_instance) { instance_double(Gitlab::Cng::Kind::Cluster, create: nil) }
    let(:ip) { instance_double(Addrinfo, ipv4_private?: true, ip_address: "127.0.0.1") }
    let(:ci_components) do
      {
        "gitlab.gitaly.image.repository" => "cng-mirror/gitaly",
        "gitlab.gitaly.image.tag" => "1fb4c252c713f33db2102315870c1936769319ac"
      }
    end

    before do
      allow(Gitlab::Cng::Deployment::Installation).to receive(:new).and_return(installation_instance)
      allow(Gitlab::Cng::Deployment::Configurations::Kind).to receive(:new).and_return(configuration_instance)
      allow(Gitlab::Cng::Kind::Cluster).to receive(:new).and_return(cluster_instance)
      allow(Gitlab::Cng::Deployment::DefaultValues).to receive(:component_ci_versions).and_return(ci_components)
      allow(Socket).to receive(:ip_address_list).and_return([ip])
    end

    it "defines kind deployment" do
      expect_command_to_include_attributes(command_name, {
        description: "Create CNG deployment against local kind k8s cluster where NAME is helm release name. " \
          "Default: gitlab",
        name: command_name,
        usage: "#{command_name} [NAME]"
      })
    end

    it "invokes kind deployment creation with correct arguments" do
      invoke_command(command_name, [], {
        namespace: "gitlab",
        ci: false
      })

      expect(Gitlab::Cng::Deployment::Installation).to have_received(:new).with(
        "gitlab",
        configuration: configuration_instance,
        namespace: "gitlab",
        ci: false,
        gitlab_domain: "127.0.0.1.nip.io",
        timeout: "10m",
        retry: 0
      )
      expect(Gitlab::Cng::Deployment::Configurations::Kind).to have_received(:new).with(
        namespace: "gitlab",
        ci: false,
        gitlab_domain: "127.0.0.1.nip.io",
        admin_password: "5iveL!fe",
        admin_token: "ypCa3Dzb23o5nvsixwPA",
        host_http_port: 80,
        host_ssh_port: 22,
        host_registry_port: 5000
      )
      expect(installation_instance).to have_received(:create)
    end

    it "creates kind cluster before deployment" do
      invoke_command(command_name, [], {
        namespace: "gitlab",
        ci: true
      })

      expect(Gitlab::Cng::Kind::Cluster).to have_received(:new).with(ci: true, host_http_port: 80, host_ssh_port: 22,
        host_registry_port: 5000)
      expect(cluster_instance).to have_received(:create)
    end

    it "passes extra environment options" do
      invoke_command(command_name, [], {
        namespace: "gitlab",
        env: ["env1=val1", "env2=val2"]
      })

      expect(Gitlab::Cng::Deployment::Installation).to have_received(:new).with(
        "gitlab",
        hash_including(env: ["env1=val1", "env2=val2"])
      )
    end

    it "only print arguments with --print-deploy-args option" do
      chart_sha = "356a1ab41be2"
      extra_opt = "opt=val"
      args = [
        *ci_components.map { |c, v| "--set #{c}=#{v}" }.join(' '),
        "--set", extra_opt,
        "--chart-sha", chart_sha
      ]

      expect do
        invoke_command(command_name, [], {
          ci: true,
          print_deploy_args: true,
          chart_sha: chart_sha,
          set: [extra_opt]
        })
      end.to output(
        match(/Received --print-deploy-args option, printing example of all deployment arguments!/).and(
          match(/cng create deployment kind #{args.join(' ')}/)
        )
      ).to_stdout

      expect(cluster_instance).not_to have_received(:create)
      expect(installation_instance).not_to have_received(:create)
    end
  end
end
