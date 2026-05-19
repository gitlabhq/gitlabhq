# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module Nuget
        module WarningHeader
          extend ::Gitlab::Utils::Override

          HEADER_NAME = 'X-NuGet-Warning'

          override :render_structured_api_error!
          def render_structured_api_error!(hash, status)
            return super unless Feature.enabled?(:nuget_warning_header, Feature.current_request)

            message = hash['message']
            header[HEADER_NAME] = message.tr("\r\n", ' ') if message.is_a?(String) && message.present?

            super
          end
        end
      end
    end
  end
end
