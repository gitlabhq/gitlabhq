# frozen_string_literal: true

module Mutations
  module Pages
    class MarkOnboardingComplete < Base
      graphql_name 'PagesMarkOnboardingComplete'

      field :onboarding_complete,
        Boolean,
        null: false,
        description: "Indicates the new onboarding_complete state of the project's Pages metadata."

      authorize :admin_project

      def resolve(project_path:)
        project = authorized_find!(project_path)

        project.mark_pages_onboarding_complete

        {
          onboarding_complete: project.pages_metadatum.onboarding_complete,
          errors: errors_on_object(project)
        }
      end
    end
  end
end
