# frozen_string_literal: true

module Gitlab
  module Orchestrator
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
          # This is defined as key value pairs to allow constructing example cli args for easier reproducibility
          #
          # @return [Hash]
          def component_ci_versions
            {
              "gitlab.gitaly.image.repository" => "#{IMAGE_REPOSITORY}/gitaly",
              "gitlab.gitaly.image.tag" => with_semver_prefix(gitaly_version),
              "gitlab.gitlab-shell.image.repository" => "#{IMAGE_REPOSITORY}/gitlab-shell",
              "gitlab.gitlab-shell.image.tag" => with_semver_prefix(gitlab_shell_version),
              "gitlab.migrations.image.repository" => "#{IMAGE_REPOSITORY}/gitlab-toolbox-ee",
              "gitlab.migrations.image.tag" => toolbox_version,
              "gitlab.toolbox.image.repository" => "#{IMAGE_REPOSITORY}/gitlab-toolbox-ee",
              "gitlab.toolbox.image.tag" => toolbox_version,
              "gitlab.sidekiq.annotations.commit" => commit_short_sha,
              "gitlab.sidekiq.image.repository" => "#{IMAGE_REPOSITORY}/gitlab-sidekiq-ee",
              "gitlab.sidekiq.image.tag" => sidekiq_version,
              "gitlab.webservice.annotations.commit" => commit_short_sha,
              "gitlab.webservice.image.repository" => "#{IMAGE_REPOSITORY}/gitlab-webservice-ee",
              "gitlab.webservice.image.tag" => webservice_version,
              "gitlab.webservice.workhorse.image" => "#{IMAGE_REPOSITORY}/gitlab-workhorse-ee",
              "gitlab.webservice.workhorse.tag" => workhorse_version,
              "gitlab.kas.image.repository" => "#{IMAGE_REPOSITORY}/gitlab-kas",
              "gitlab.kas.image.tag" => with_semver_prefix(kas_version),
              "gitlab.registry.image.repository" => "#{IMAGE_REPOSITORY}/gitlab-container-registry",
              "gitlab.registry.image.tag" => registry_version
            }
          end

          private

          # Semver compatible version
          #
          # @param [String] version
          # @return [Boolean]
          def with_semver_prefix(version)
            return version unless version.match?(/^[0-9]+\.[0-9]+\.[0-9]+(-rc[0-9]+)?(-ee)?$/)

            "v#{version}"
          end
        end
      end
    end
  end
end
