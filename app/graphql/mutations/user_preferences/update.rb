# frozen_string_literal: true

module Mutations
  module UserPreferences
    class Update < BaseMutation
      graphql_name 'UserPreferencesUpdate'

      argument :issues_sort, Types::IssueSortEnum,
               required: false,
               description: 'Sort order for issue lists.'
      argument :visibility_pipeline_id_type, Types::VisibilityPipelineIdTypeEnum,
               required: false,
               description: 'Determines whether the pipeline list shows ID or IID.'

      field :user_preferences,
            Types::UserPreferencesType,
            null: true,
            description: 'User preferences after mutation.'

      def resolve(**attributes)
        user_preferences = current_user.user_preference
        user_preferences.update(attributes)

        {
          user_preferences: user_preferences.valid? ? user_preferences : nil,
          errors: errors_on_object(user_preferences)
        }
      end
    end
  end
end
