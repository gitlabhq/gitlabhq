# frozen_string_literal: true

module Resolvers
  module AlertManagement
    module Alerts
      class AssigneesResolver < BaseResolver
        type Types::UserType, null: true

        # With lazy-loaded assignees, authorizations should be avoided
        # in earlier phases to take advantage of batching. See
        # AssigneeLoader for authorization steps.
        # https://gitlab.com/gitlab-org/gitlab/-/issues/217767
        def self.skip_authorizations?
          true
        end

        def resolve(**args)
          return [] unless Feature.enabled?(:alert_assignee)

          ::Gitlab::Graphql::Loaders::AlertManagement::Alerts::AssigneesLoader
            .new(object.id, user_authorization_filter)
            .find
        end

        private

        def user_authorization_filter
          proc do |users|
            users.select { |user| Ability.allowed?(context[:current_user], :read_user, user) }
          end
        end
      end
    end
  end
end
