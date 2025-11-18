# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module CurrentOrganization
      class Server
        include Sidekiq::ServerMiddleware

        # rubocop:disable Gitlab/AvoidCurrentOrganization -- We need to assign Current.organization in workers
        def call(_worker, _job, _queue)
          organization_id = Gitlab::ApplicationContext.current_context_attribute('organization_id')

          if organization_id
            begin
              ::Current.organization = ::Organizations::Organization.find(organization_id)
            rescue ActiveRecord::RecordNotFound
              raise Sidekiq::JobRetry::Skip
            end
          end

          yield
        end
        # rubocop:enable Gitlab/AvoidCurrentOrganization
      end
    end
  end
end
