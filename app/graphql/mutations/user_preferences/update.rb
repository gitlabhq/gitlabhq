# frozen_string_literal: true

module Mutations
  module UserPreferences
    class Update < BaseMutation
      graphql_name 'UserPreferencesUpdate'

      argument :issues_sort, Types::IssueSortEnum,
               required: false,
               description: 'Sort order for issue lists.'

      field :user_preferences,
            Types::UserPreferencesType,
            null: true,
            description: 'User preferences after mutation.'

      def ready?(**args)
        if disabled_sort_value?(args)
          raise Gitlab::Graphql::Errors::ArgumentError,
                'Feature flag `incident_escalations` must be enabled to use this sort order.'
        end

        super
      end

      def resolve(**attributes)
        user_preferences = current_user.user_preference
        user_preferences.update(attributes)

        {
          user_preferences: user_preferences.valid? ? user_preferences : nil,
          errors: errors_on_object(user_preferences)
        }
      end

      private

      def disabled_sort_value?(args)
        return false unless [:escalation_status_asc, :escalation_status_desc].include?(args[:issues_sort])

        Feature.disabled?(:incident_escalations, default_enabled: :yaml)
      end
    end
  end
end
