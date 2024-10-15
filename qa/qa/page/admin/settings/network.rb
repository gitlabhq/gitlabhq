# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Settings
        class Network < Page::Base
          include QA::Page::Settings::Common

          view 'app/views/admin/application_settings/network.html.haml' do
            element 'ip-limits-content'
            element 'outbound-requests-content'
          end

          def expand_user_ip_limits(&block)
            expand_content('ip-limits-content') do
              Component::IpLimits.perform(&block)
            end
          end

          def expand_outbound_requests(&block)
            expand_content('outbound-requests-content') do
              Component::OutboundRequests.perform(&block)
            end
          end
        end
      end
    end
  end
end
