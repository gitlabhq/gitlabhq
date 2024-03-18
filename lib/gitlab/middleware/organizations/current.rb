# frozen_string_literal: true

module Gitlab
  module Middleware
    module Organizations
      # Logic of setting the Current.organization:
      #   - Request header value from injection on frontend
      #   - TODO: Request header from injection from routing layer
      #     see ideas in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144811#note_1784126192
      class Current
        def initialize(app)
          @app = app
        end

        def call(env)
          @request = Rack::Request.new(env)

          ::Current.organization = calculated_organization

          @app.call(env)
        end

        private

        POSITIVE_INTEGER_REGEX = %r{\A[1-9]\d*\z}

        def calculated_organization
          find_from_header
        end

        def find_from_header
          header_organization_id = @request.get_header(::Organizations::ORGANIZATION_HTTP_HEADER)

          return unless header_organization_id.to_s.match?(POSITIVE_INTEGER_REGEX) # don't do unnecessary query

          ::Organizations::Organization.find_by_id(header_organization_id)
        end
      end
    end
  end
end
