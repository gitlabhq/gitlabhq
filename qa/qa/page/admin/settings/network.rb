# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Settings
        class Network < Page::Base
          include QA::Page::Settings::Common

          view 'app/views/admin/application_settings/network.html.haml' do
            element :ip_limits_section
          end

          def expand_ip_limits(&block)
            expand_section(:ip_limits_section) do
              Component::IpLimits.perform(&block)
            end
          end
        end
      end
    end
  end
end
