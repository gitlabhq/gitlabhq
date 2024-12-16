# frozen_string_literal: true

module Gitlab
  module Cng
    module Deployment
      # Helpers for common chart values
      #
      class DefaultValues
        extend Helpers::CI

        IMAGE_REPOSITORY = "registry.gitlab.com/gitlab-org/build/cng-mirror"

        class << self
          # Main common chart values
          #
          # @param [String] domain
          # @return [Hash]
          def common_values(domain)
            {
              global: {
                hosts: {
                  domain: domain,
                  https: false
                },
                ingress: {
                  configureCertmanager: false,
                  tls: {
                    enabled: false
                  }
                },
                appConfig: {
                  applicationSettingsCacheSeconds: 0,
                  dependencyProxy: {
                    enabled: true
                  }
                }
              },
              gitlab: { "gitlab-exporter": { enabled: false } },
              redis: { metrics: { enabled: false } },
              prometheus: { install: false },
              certmanager: { install: false },
              "gitlab-runner": { install: false }
            }
          end

          # Key value pairs for ci specific component version values
          #
          # This is defined as key value pairs to allow constructing example cli args for easier reproducability
          #
          # @return [Hash]
          def component_ci_versions
            {
              "gitlab.gitaly.image.repository" => "#{IMAGE_REPOSITORY}/gitaly",
              "gitlab.gitaly.image.tag" => semver?(gitaly_version) ? "v#{gitaly_version}" : gitaly_version,
              "gitlab.gitlab-shell.image.repository" => "#{IMAGE_REPOSITORY}/gitlab-shell",
              "gitlab.gitlab-shell.image.tag" => "v#{gitlab_shell_version}",
              "gitlab.migrations.image.repository" => "#{IMAGE_REPOSITORY}/gitlab-toolbox-ee",
              "gitlab.migrations.image.tag" => commit_sha,
              "gitlab.toolbox.image.repository" => "#{IMAGE_REPOSITORY}/gitlab-toolbox-ee",
              "gitlab.toolbox.image.tag" => commit_sha,
              "gitlab.sidekiq.annotations.commit" => commit_short_sha,
              "gitlab.sidekiq.image.repository" => "#{IMAGE_REPOSITORY}/gitlab-sidekiq-ee",
              "gitlab.sidekiq.image.tag" => commit_sha,
              "gitlab.webservice.annotations.commit" => commit_short_sha,
              "gitlab.webservice.image.repository" => "#{IMAGE_REPOSITORY}/gitlab-webservice-ee",
              "gitlab.webservice.image.tag" => commit_sha,
              "gitlab.webservice.workhorse.image" => "#{IMAGE_REPOSITORY}/gitlab-workhorse-ee",
              "gitlab.webservice.workhorse.tag" => commit_sha
            }
          end

          private

          # Semver compatible version
          #
          # @param [String] version
          # @return [Boolean]
          def semver?(version)
            version.match?(/^[0-9]+\.[0-9]+\.[0-9]+(-rc[0-9]+)?(-ee)?$/)
          end
        end
      end
    end
  end
end
