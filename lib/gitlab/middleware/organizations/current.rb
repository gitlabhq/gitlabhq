# frozen_string_literal: true

module Gitlab
  module Middleware
    module Organizations
      class Current
        def initialize(app)
          @app = app
        end

        def call(env)
          # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/437541 to enhance the finder:
          #   - Separate logged in vs not logged in user(perhaps using session)
          #   - Authenticated:
          #     - Request header
          #     - Rails session value to drive the finder
          #     - First organization current user is a user of
          #   - Unauthenticated:
          #     - default organization
          if Feature.enabled?(:current_organization_middleware, type: :gitlab_com_derisk)
            ::Current.organization = ::Organizations::Organization.default_organization
          end

          @app.call(env)
        end
      end
    end
  end
end
