# frozen_string_literal: true

require "net/http"

module Gitlab
  module Cng
    module Helm
      class Client
        include Helpers::Shell
        include Helpers::Output

        GITLAB_CHART_PREFIX = "gitlab"
        GITLAB_CHART_URL = "https://charts.gitlab.io"
        GITLAB_CHART_PROJECT_URL = "https://gitlab.com/gitlab-org/charts/gitlab"

        REPOSITORY_CACHE_VARIABLE_NAME = "CNG_HELM_REPOSITORY_CACHE"

        # Error raised by helm client class
        Error = Class.new(StandardError)

        # Add helm chart repository
        #
        # @param [String] name
        # @param [String] url
        # @return [void]
        def add_helm_chart(name, url)
          log("Adding helm chart '#{url}'", :info)
          puts(run_helm(%W[repo add #{name} #{url}]).tap do |output|
            # when cache is present, the command will skip with 0 exit code but repo update still needs to be performed
            raise(Error, output) if output.include?("already exists with the same configuration")
          end)
        rescue Error => e
          if e.message.include?("already exists")
            log("helm chart repo already exists, updating", :warn)
            return puts(run_helm(%W[repo update #{name}]))
          end

          raise(Error, e.message)
        end

        # Add helm chart and return reference
        #
        # @param [String] sha fetch and package helm chart using specific repo sha
        # @return [String] chart reference or path to packaged chart tgz
        def add_gitlab_helm_chart(sha = nil)
          return package_chart(sha) if sha

          add_helm_chart(GITLAB_CHART_PREFIX, GITLAB_CHART_URL)
          "#{GITLAB_CHART_PREFIX}/gitlab"
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

        # Uninstall helm release
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

        # Custom repository cache folder
        #
        # @return [String]
        def repository_cache
          @repository_cache ||= ENV[REPOSITORY_CACHE_VARIABLE_NAME] || ""
        end

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
          chart_tar = "gitlab-#{sha}.tgz"
          cached_chart_tar = File.join(repository_cache, chart_tar)

          if repository_cache.present? && File.exist?(cached_chart_tar)
            puts "Cached version of chart found at #{cached_chart_tar}, skipping packaging"
            return cached_chart_tar
          end

          puts run_helm(%W[package --dependency-update --destination #{chart_dir} #{chart_dir}])
          packaged_chart_tar = Dir.glob("#{chart_dir}/gitlab-*.tgz").first
          raise "Failed to package chart" unless File.exist?(packaged_chart_tar)

          FileUtils.cp(packaged_chart_tar, cached_chart_tar) if File.directory?(repository_cache)
          packaged_chart_tar
        end

        # Download and extract helm chart
        #
        # @param [String] sha
        # @return [String] path to extracted repo
        def fetch_chart_repo(sha)
          uri = URI("#{GITLAB_CHART_PROJECT_URL}/-/archive/#{sha}/gitlab-#{sha}.tar")
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
          helm_cmd = ["helm", *cmd]
          helm_cmd.push("--repository-cache", repository_cache) if repository_cache.present?
          execute_shell(helm_cmd, stdin_data: stdin)
        rescue Helpers::Shell::CommandFailure => e
          raise(Error, e.message)
        end
      end
    end
  end
end
