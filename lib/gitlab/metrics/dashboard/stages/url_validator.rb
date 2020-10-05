# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Stages
        class UrlValidator < BaseStage
          def transform!
            validate_dashboard_links(dashboard)

            validate_chart_links(dashboard)
          end

          private

          def blocker_args
            {
              schemes: %w(http https),
              ports: [],
              allow_localhost: allow_setting_local_requests?,
              allow_local_network: allow_setting_local_requests?,
              ascii_only: false,
              enforce_user: false,
              enforce_sanitization: false,
              dns_rebind_protection: true
            }
          end

          def allow_setting_local_requests?
            Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
          end

          def validate_dashboard_links(dashboard)
            validate_links(dashboard[:links])
          end

          def validate_chart_links(dashboard)
            dashboard[:panel_groups].each do |panel_group|
              panel_group[:panels].each do |panel|
                validate_links(panel[:links])
              end
            end
          end

          def validate_links(links)
            links&.each do |link|
              next unless link.is_a? Hash

              Gitlab::UrlBlocker.validate!(link[:url], **blocker_args)
            rescue Gitlab::UrlBlocker::BlockedUrlError
              link[:url] = ''
            end
          end
        end
      end
    end
  end
end
