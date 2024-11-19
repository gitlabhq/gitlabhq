# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Commands::Destroy do
  include_context "with command testing helper"

  describe "cluster command" do
    let(:prompt) { instance_double(TTY::Prompt, yes?: prompt_response) }
    let(:prompt_response) { true }
    let(:command_name) { "cluster" }

    before do
      allow(Gitlab::Cng::Kind::Cluster).to receive(:destroy)
      allow(TTY::Prompt).to receive(:new).and_return(prompt)
    end

    it "defines cluster command" do
      expect_command_to_include_attributes(command_name, {
        description: "Destroy kind cluster created for kind type deployments",
        usage: command_name
      })
    end

    context "with accepted prompt" do
      it "invokes kind cluster deletion" do
        invoke_command(command_name, [])

        expect(Gitlab::Cng::Kind::Cluster).to have_received(:destroy)
      end
    end

    context "with rejected prompt" do
      let(:prompt_response) { false }

      it "skips cluster deletion" do
        invoke_command(command_name, [])

        expect(Gitlab::Cng::Kind::Cluster).not_to have_received(:destroy)
      end
    end
  end

  describe "deployment command" do
    let(:prompt) { instance_double(TTY::Prompt, yes?: prompt_response) }
    let(:prompt_response) { true }
    let(:command_name) { "deployment" }

    before do
      allow(Gitlab::Cng::Deployment::Installation).to receive(:uninstall)
      allow(TTY::Prompt).to receive(:new).and_return(prompt)
    end

    it "defines deployment command" do
      expect_command_to_include_attributes(command_name, {
        description: "Destroy specific deployment and all it's resources, " \
          "where NAME is helm relase name. " \
          "Default: gitlab",
        name: command_name,
        usage: "#{command_name} [NAME]"
      })
    end

    context "with accepted prompt" do
      let(:kind_cleanup) { instance_double(Gitlab::Cng::Deployment::Configurations::Cleanup::Kind) }
      let(:configuration) { "kind" }

      before do
        allow(Gitlab::Cng::Deployment::Configurations::Cleanup::Kind).to receive(:new).and_return(kind_cleanup)
      end

      context "without type argument" do
        before do
          allow(prompt).to receive(:select).and_return(configuration)
        end

        it "fetches deployment type via prompt" do
          invoke_command(command_name, ["gitlab"], {})

          expect(Gitlab::Cng::Deployment::Configurations::Cleanup::Kind).to have_received(:new).with("gitlab")
          expect(prompt).to have_received(:select).with(
            "Select deployment configuration type:",
            array_including(configuration)
          )
          expect(Gitlab::Cng::Deployment::Installation).to have_received(:uninstall).with(
            "gitlab",
            cleanup_configuration: kind_cleanup,
            timeout: "10m"
          )
        end
      end

      context "with type argument" do
        it "fetches deployment type via argument" do
          invoke_command(command_name, ["test-deploy"], { type: configuration, timeout: "5m", namespace: "test" })

          expect(Gitlab::Cng::Deployment::Configurations::Cleanup::Kind).to have_received(:new).with("test")
          expect(Gitlab::Cng::Deployment::Installation).to have_received(:uninstall).with(
            "test-deploy",
            cleanup_configuration: kind_cleanup,
            timeout: "5m"
          )
        end
      end
    end

    context "with rejected prompt" do
      let(:prompt_response) { false }

      it "skips deployment deletion" do
        invoke_command(command_name, [], { name: "gitlab" })

        expect(Gitlab::Cng::Deployment::Installation).not_to have_received(:uninstall)
      end
    end
  end
end
