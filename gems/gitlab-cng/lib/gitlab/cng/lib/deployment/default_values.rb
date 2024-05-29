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
                  applicationSettingsCacheSeconds: 0
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
              "gitaly.image.repository" => "#{IMAGE_REPOSITORY}/gitaly",
              "gitaly.image.tag" => gitaly_version,
              "gitlab-shell.image.repository" => "#{IMAGE_REPOSITORY}/gitlab-shell",
              "gitlab-shell.image.tag" => "v#{gitlab_shell_version}",
              "migrations.image.repository" => "#{IMAGE_REPOSITORY}/gitlab-toolbox-ee",
              "migrations.image.tag" => commit_sha,
              "toolbox.image.repository" => "#{IMAGE_REPOSITORY}/gitlab-toolbox-ee",
              "toolbox.image.tag" => commit_sha,
              "sidekiq.annotations.commit" => commit_short_sha,
              "sidekiq.image.repository" => "#{IMAGE_REPOSITORY}/gitlab-sidekiq-ee",
              "sidekiq.image.tag" => commit_sha,
              "webservice.annotations.commit" => commit_short_sha,
              "webservice.image.repository" => "#{IMAGE_REPOSITORY}/gitlab-webservice-ee",
              "webservice.image.tag" => commit_sha,
              "webservice.workhorse.image" => "#{IMAGE_REPOSITORY}/gitlab-workhorse-ee",
              "webservice.workhorse.tag" => commit_sha
            }
          end
        end
      end
    end
  end
end
