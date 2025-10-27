# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Releaser
        include ::Gitlab::Utils::StrongMemoize

        RELEASE_CLI_CREATE_BASE_COMMAND = 'release-cli create'
        RELEASE_CLI_CREATE_SINGLE_FLAGS = %i[name description tag_name tag_message ref released_at].freeze
        RELEASE_CLI_CREATE_ARRAY_FLAGS = %i[milestones].freeze
        RELEASE_CLI_CATALOG_PUBLISH_FLAG = '--catalog-publish'

        # If these versions or error messages are updated, the documentation should be updated as well.

        TROUBLESHOOTING_URL = Rails.application.routes.url_helpers.help_page_url('user/project/releases/_index.md', anchor: 'gitlab-cli-version-requirement')
        GLAB_REQUIRED_VERSION = '1.58.0'
        GLAB_WARNING_MESSAGE = "Warning: release-cli will not be supported after 20.0. Please use glab version >= #{GLAB_REQUIRED_VERSION}. Troubleshooting: #{TROUBLESHOOTING_URL}".freeze

        GLAB_ENV_SET_UNIX = 'export GITLAB_HOST=$CI_SERVER_URL'
        GLAB_ENV_SET_WINDOWS = '$$env:GITLAB_HOST = $$env:CI_SERVER_URL'
        GLAB_LOGIN_UNIX = 'glab auth login --job-token $CI_JOB_TOKEN --hostname "$CI_SERVER_FQDN" --api-protocol $CI_SERVER_PROTOCOL'
        GLAB_LOGIN_WINDOWS = 'glab auth login --job-token $$env:CI_JOB_TOKEN --hostname "$$env:CI_SERVER_FQDN" --api-protocol $$env:CI_SERVER_PROTOCOL'
        GLAB_CREATE_UNIX = 'glab release create -R $CI_PROJECT_PATH'
        GLAB_CREATE_WINDOWS = 'glab release create -R $$env:CI_PROJECT_PATH'
        GLAB_PUBLISH_TO_CATALOG_FLAG = '--publish-to-catalog' # enables publishing to the catalog after creating the release
        GLAB_NO_UPDATE_FLAG = '--no-update' # disables updating the release if it already exists
        GLAB_NO_CLOSE_MILESTONE_FLAG = '--no-close-milestone' # disables closing the milestone after creating the release

        GLAB_CA_CERT_FILENAME = 'ca_cert_for_releasing_with_glab.pem'

        # This approach was inherited from
        # https://gitlab.com/gitlab-org/release-cli/-/blob/v0.24.0/internal/app/http_client.go
        # We check if ADDITIONAL_CA_CERT_BUNDLE contains inline certificate content or is a file path.
        # - If it contains newlines, it's inline certificate content and we write it to a temporary file
        # - If it doesn't contain newlines, it's a file path and we use it directly
        GLAB_CA_CERT_CONFIG_UNIX = <<~BASH.chomp.freeze
          if [ -n "$ADDITIONAL_CA_CERT_BUNDLE" ]; then
            echo "Setting CA certificate for $CI_SERVER_FQDN"

            if echo "$ADDITIONAL_CA_CERT_BUNDLE" | grep -q $'\\n'; then
              echo "$ADDITIONAL_CA_CERT_BUNDLE" > "#{GLAB_CA_CERT_FILENAME}"
              glab config set ca_cert "#{GLAB_CA_CERT_FILENAME}" --host "$CI_SERVER_FQDN"
            else
              glab config set ca_cert "$ADDITIONAL_CA_CERT_BUNDLE" --host "$CI_SERVER_FQDN"
            fi
          fi
        BASH
        GLAB_CA_CERT_CLEANUP_UNIX = <<~BASH.chomp.freeze
          if [ -f "#{GLAB_CA_CERT_FILENAME}" ]; then
            rm -f "#{GLAB_CA_CERT_FILENAME}"
          fi
        BASH
        GLAB_CA_CERT_CONFIG_WINDOWS = <<~POWERSHELL.chomp.freeze
          if ($$env:ADDITIONAL_CA_CERT_BUNDLE) {
            Write-Output "Setting CA certificate for $$env:CI_SERVER_FQDN"

            if ($$env:ADDITIONAL_CA_CERT_BUNDLE -match "[`r`n]") {
              "$$env:ADDITIONAL_CA_CERT_BUNDLE" > "#{GLAB_CA_CERT_FILENAME}"
              glab config set ca_cert "#{GLAB_CA_CERT_FILENAME}" --host "$$env:CI_SERVER_FQDN"
            }
            else {
              glab config set ca_cert "$$env:ADDITIONAL_CA_CERT_BUNDLE" --host "$$env:CI_SERVER_FQDN"
            }
          }
        POWERSHELL
        GLAB_CA_CERT_CLEANUP_WINDOWS = <<~POWERSHELL.chomp.freeze
          if (Test-Path "#{GLAB_CA_CERT_FILENAME}") {
            Remove-Item -Force "#{GLAB_CA_CERT_FILENAME}"
          }
        POWERSHELL

        attr_reader :job, :config, :runner_manager

        def initialize(job:)
          @job = job
          @config = job.options[:release]
          @runner_manager = job.runner_manager

          Gitlab::AppJsonLogger.info(
            class: self.class.to_s,
            message: 'The release script for the release build is being prepared.',
            runner_id: job.runner&.id,
            runner_type: job.runner&.runner_type,
            runner_platform: job.runner_manager&.platform
          )
        end

        def script
          if runner_manager&.platform == 'windows'
            [windows_script]
          else
            [unix_script]
          end
        end

        private

        def windows_script
          <<~POWERSHELL
          if (Get-Command glab -ErrorAction SilentlyContinue) {
            $$glabVersionOutput = (glab --version | Select-Object -First 1) -as [string]

            if ($$glabVersionOutput -match 'glab (\\\d+\\\.\\\d+\\\.\\\d+)') {
              if ([version]$$matches[1] -ge [version]"#{GLAB_REQUIRED_VERSION}") {
                #{GLAB_ENV_SET_WINDOWS}
                #{GLAB_CA_CERT_CONFIG_WINDOWS}
                #{GLAB_LOGIN_WINDOWS}
                #{glab_create_command('windows')}
                #{GLAB_CA_CERT_CLEANUP_WINDOWS}
              }
              else {
                Write-Output "#{GLAB_WARNING_MESSAGE}"
                #{script_with_release_cli}
              }
            }
            else {
              Write-Output "#{GLAB_WARNING_MESSAGE}"
              #{script_with_release_cli}
            }
          }
          else {
            Write-Output "#{GLAB_WARNING_MESSAGE}"
            #{script_with_release_cli}
          }
          POWERSHELL
        end

        def unix_script
          <<~BASH
          if command -v glab &> /dev/null; then
            if [ "$(printf "%s\\n%s" "#{GLAB_REQUIRED_VERSION}" "$(glab --version | grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+')" | sort -V | head -n1)" = "#{GLAB_REQUIRED_VERSION}" ]; then
              #{GLAB_ENV_SET_UNIX}
              #{GLAB_CA_CERT_CONFIG_UNIX}
              #{GLAB_LOGIN_UNIX}
              #{glab_create_command('unix')}
              #{GLAB_CA_CERT_CLEANUP_UNIX}
            else
              echo "#{GLAB_WARNING_MESSAGE}"

              #{script_with_release_cli}
            fi
          else
            echo "#{GLAB_WARNING_MESSAGE}"

            #{script_with_release_cli}
          fi
          BASH
        end

        def script_with_release_cli
          command = RELEASE_CLI_CREATE_BASE_COMMAND.dup
          config.slice(*RELEASE_CLI_CREATE_SINGLE_FLAGS).each { |k, v| command.concat(" --#{k.to_s.dasherize} \"#{v}\"") }
          config.slice(*RELEASE_CLI_CREATE_ARRAY_FLAGS).each { |k, v| v.each { |elem| command.concat(" --#{k.to_s.singularize.dasherize} \"#{elem}\"") } }
          create_asset_links.each { |link| command.concat(" --assets-link #{stringified_json(link)}") }

          if catalog_publish? && ci_release_cli_catalog_publish_option?
            command.concat(" #{RELEASE_CLI_CATALOG_PUBLISH_FLAG}")
          end

          command.freeze
        end

        def glab_create_command(platform) # rubocop:disable Metrics/ -- It's more readable this way
          if platform == 'windows'
            command = GLAB_CREATE_WINDOWS.dup

            # More information: https://gitlab.com/groups/gitlab-org/-/epics/15437#note_2432564707
            tag_name = config[:tag_name].presence || '$$env:CI_COMMIT_TAG'
            ref = config[:ref].presence || '$$env:CI_COMMIT_SHA'
          else
            command = GLAB_CREATE_UNIX.dup

            # More information: https://gitlab.com/groups/gitlab-org/-/epics/15437#note_2432564707
            tag_name = config[:tag_name].presence || '$CI_COMMIT_TAG'
            ref = config[:ref].presence || '$CI_COMMIT_SHA'
          end

          command.concat(" \"#{tag_name}\"")
          command.concat(" --assets-links #{stringified_json(create_asset_links)}") if create_asset_links.present?
          command.concat(" --milestone \"#{config[:milestones].join(',')}\"") if config[:milestones].present?
          command.concat(" --name \"#{config[:name]}\"") if config[:name].present?

          if config[:description].present?
            # More information: https://gitlab.com/gitlab-org/cli/-/issues/7762
            command.concat(" --experimental-notes-text-or-file \"#{config[:description]}\"")
          end

          command.concat(" --ref \"#{ref}\"") if ref.present?
          command.concat(" --tag-message \"#{config[:tag_message]}\"") if config[:tag_message].present?
          command.concat(" --released-at \"#{config[:released_at]}\"") if config[:released_at].present?

          command.concat(" #{GLAB_NO_UPDATE_FLAG} #{GLAB_NO_CLOSE_MILESTONE_FLAG}")

          if catalog_publish? && ci_release_cli_catalog_publish_option?
            command.concat(" #{GLAB_PUBLISH_TO_CATALOG_FLAG}")
          end

          command.freeze
        end

        def create_asset_links
          config.dig(:assets, :links) || []
        end

        def stringified_json(object)
          object.to_json.to_json.to_s
        end

        def catalog_publish?
          job.project.catalog_resource
        end
        strong_memoize_attr :catalog_publish?

        def ci_release_cli_catalog_publish_option?
          ::Feature.enabled?(:ci_release_cli_catalog_publish_option, job.project)
        end
        strong_memoize_attr :ci_release_cli_catalog_publish_option?
      end
    end
  end
end
