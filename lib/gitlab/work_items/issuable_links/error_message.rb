# frozen_string_literal: true

module Gitlab
  module WorkItems
    module IssuableLinks
      class ErrorMessage
        def initialize(target_type:)
          @target_type = target_type
        end

        def for_http_status(http_status)
          case http_status
          when 404
            not_found
          when 403
            no_permission_error
          when 409
            already_assigned
          end
        end

        def already_assigned
          format(_('%{issuable}(s) already assigned'), issuable: target_type.capitalize)
        end

        def no_permission_error
          format(
            _("Could not link %{issuables}. You must be a member of the project or group of both %{issuables}."),
            issuables: target_type.to_s.pluralize
          )
        end

        def not_found
          format(_('No matching %{issuable} found. Make sure that you are adding a valid %{issuable} URL.'),
            issuable: target_type)
        end

        attr_reader :target_type
      end
    end
  end
end
