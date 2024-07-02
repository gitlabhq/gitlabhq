# frozen_string_literal: true

require "net/http"

module Gitlab
  module Cng
    module Helm
      class Client
        include Helpers::Shell
        include Helpers::Output

        HELM_CHART_PREFIX = "gitlab"
        HELM_CHART = "https://charts.gitlab.io"
        HELM_CHART_REPO = "https://gitlab.com/gitlab-org/charts/gitlab"

        # Error raised by helm client class
        Error = Class.new(StandardError)

        # Add helm chart and return reference
        #
        # @param [String] sha fetch and package helm chart using specific repo sha
        # @return [String] chart reference or path to packaged chart tgz
        def add_helm_chart(sha = nil)
          return package_chart(sha) if sha

          log("Adding gitlab helm chart '#{HELM_CHART}'", :info)
          puts run_helm(%W[repo add #{HELM_CHART_PREFIX} #{HELM_CHART}])
          "#{HELM_CHART_PREFIX}/gitlab"
        rescue Error => e
          if e.message.include?("already exists")
            log("helm chart repo already exists, updating", :warn)
            puts(run_helm(%w[repo update gitlab]))
            return "#{HELM_CHART_PREFIX}/gitlab"
          end

          raise(Error, e.message)
        end

        # Run helm upgrade command with --install argument
        #
        # @param [String] name deployment name
        # @param [String] chart helm chart reference
        # @param [String] namespace deployment namespace
        # @param [String] timeout timeout value like 5s, 10m
        # @param [String] values yml string with helm values
        # @param [Array] args extra arguments to pass to command
        # @return [void]
        def upgrade(name, chart, namespace:, timeout:, values:, args: [])
          log("Upgrading helm release '#{name}' in namespace '#{namespace}'", :info)
          puts run_helm([
            "upgrade", "--install", name, chart,
            "--namespace", namespace,
            "--timeout", timeout,
            "--values", "-",
            "--wait",
            *args
          ], values)
        end

        # Uninstall helm relase
        #
        # @param [String] name
        # @param [String] namespace
        # @param [String] timeout
        # @return [void]
        def uninstall(name, namespace:, timeout:)
          log("Uninstalling helm release '#{name}' in namespace '#{namespace}'", :info)
          puts run_helm(%W[uninstall #{name} --namespace #{namespace} --timeout #{timeout} --wait])
        end

        # Display status of helm release
        #
        # @param [String] name
        # @param [String] namespace
        # @return [<String, nil>] status of helm release or nil if release is not found
        def status(name, namespace:)
          run_helm(%W[status #{name} --namespace #{namespace}])
        rescue Error => e
          e.message.include?("release: not found") ? nil : raise(e)
        end

        private

        # Temporary directory for helm chart
        #
        # @return [String]
        def tmp_dir
          Helpers::Utils.tmp_dir
        end

        # Create chart package from specific chart repo sha
        #
        # @param [String] sha
        # @return [String] path to package
        def package_chart(sha)
          log("Packaging chart for git sha '#{sha}'", :info)
          chart_dir = fetch_chart_repo(sha)
          puts run_helm(%W[package --dependency-update --destination #{chart_dir} #{chart_dir}])

          chart_tar = Dir.glob("#{chart_dir}/gitlab-*.tgz").first
          raise "Failed to package chart" unless chart_tar

          chart_tar
        end

        # Download and extract helm chart
        #
        # @param [String] sha
        # @return [String] path to extracted repo
        def fetch_chart_repo(sha)
          uri = URI("#{HELM_CHART_REPO}/-/archive/#{sha}/gitlab-#{sha}.tar")
          res = Net::HTTP.get_response(uri)
          raise "Failed to download chart, got response code: #{res.code}" unless res.code == "200"

          tar = File.join(tmp_dir, "gitlab-#{sha}.tar").tap { |path| File.write(path, res.body) }
          execute_shell(["tar", "-xf", tar, "-C", tmp_dir])
          File.join(tmp_dir, "gitlab-#{sha}")
        end

        # Run helm command
        #
        # @param [Array] cmd
        # @return [String]
        def run_helm(cmd, stdin = nil)
          execute_shell(["helm", *cmd], stdin_data: stdin)
        rescue Helpers::Shell::CommandFailure => e
          raise(Error, e.message)
        end
      end
    end
  end
end
