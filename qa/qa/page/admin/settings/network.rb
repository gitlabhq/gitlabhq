# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Settings
        class Network < Page::Base
          include QA::Page::Settings::Common

          view 'app/views/admin/application_settings/network.html.haml' do
            element :ip_limits_content
            element :outbound_requests_content
          end

          def expand_ip_limits(&block)
            expand_content(:ip_limits_content) do
              Component::IpLimits.perform(&block)
            end
          end

          def expand_outbound_requests(&block)
            expand_content(:outbound_requests_content) do
              Component::OutboundRequests.perform(&block)
            end
          end
        end
      end
    end
  end
end
