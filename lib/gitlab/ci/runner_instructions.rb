# frozen_string_literal: true

module Gitlab
  module Ci
    class RunnerInstructions
      class ArgumentError < ::ArgumentError; end

      include Gitlab::Allowable

      OS = {
        linux: {
          human_readable_name: "Linux",
          download_locations: {
            amd64: "https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64",
            '386': "https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-386",
            arm: "https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-arm",
            arm64: "https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-arm64"
          },
          install_script_template_path: "lib/gitlab/ci/runner_instructions/templates/linux/install.sh",
          runner_executable: "sudo gitlab-runner"
        },
        osx: {
          human_readable_name: "macOS",
          download_locations: {
            amd64: "https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-darwin-amd64"
          },
          install_script_template_path: "lib/gitlab/ci/runner_instructions/templates/osx/install.sh",
          runner_executable: "sudo gitlab-runner"
        },
        windows: {
          human_readable_name: "Windows",
          download_locations: {
            amd64: "https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-windows-amd64.exe",
            '386': "https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-windows-386.exe"
          },
          install_script_template_path: "lib/gitlab/ci/runner_instructions/templates/windows/install.ps1",
          runner_executable: "./gitlab-runner.exe"
        }
      }.freeze

      OTHER_ENVIRONMENTS = {
        docker: {
          human_readable_name: "Docker",
          installation_instructions_url: "https://docs.gitlab.com/runner/install/docker.html"
        },
        kubernetes: {
          human_readable_name: "Kubernetes",
          installation_instructions_url: "https://docs.gitlab.com/runner/install/kubernetes.html"
        }
      }.freeze

      attr_reader :errors

      def initialize(os:, arch:)
        @os = os
        @arch = arch
        @errors = []

        validate_params
      end

      def install_script
        with_error_handling [Gitlab::Ci::RunnerInstructions::ArgumentError] do
          raise Gitlab::Ci::RunnerInstructions::ArgumentError, s_('Architecture not found for OS') unless environment[:download_locations].key?(@arch.to_sym)

          replace_variables(get_file(environment[:install_script_template_path]))
        end
      end

      def register_command
        with_error_handling [Gitlab::Ci::RunnerInstructions::ArgumentError, Gitlab::Access::AccessDeniedError] do
          raise Gitlab::Ci::RunnerInstructions::ArgumentError, s_('No runner executable') unless environment[:runner_executable]

          server_url = Gitlab::Routing.url_helpers.root_url(only_path: false)
          runner_executable = environment[:runner_executable]

          "#{runner_executable} register --url #{server_url} --registration-token $REGISTRATION_TOKEN"
        end
      end

      private

      def with_error_handling(exceptions)
        return if errors.present?

        yield
      rescue *exceptions => e
        @errors << e.message
        nil
      end

      def environment
        @environment ||= OS[@os.to_sym] || ( raise Gitlab::Ci::RunnerInstructions::ArgumentError, s_('Invalid OS') )
      end

      def validate_params
        @errors << s_('Missing OS') unless @os.present?
        @errors << s_('Missing arch') unless @arch.present?
      end

      def replace_variables(expression)
        expression.sub('${GITLAB_CI_RUNNER_DOWNLOAD_LOCATION}', "#{environment[:download_locations][@arch.to_sym]}")
      end

      def get_file(path)
        File.read(Rails.root.join(path).to_s)
      end
    end
  end
end
