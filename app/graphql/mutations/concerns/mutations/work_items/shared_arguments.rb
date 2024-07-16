# frozen_string_literal: true

module Mutations
  module WorkItems
    module SharedArguments
      extend ActiveSupport::Concern

      included do
        argument :assignees_widget,
          ::Types::WorkItems::Widgets::AssigneesInputType,
          required: false,
          description: 'Input for assignees widget.'
        argument :confidential,
          GraphQL::Types::Boolean,
          required: false,
          description: 'Sets the work item confidentiality.'
        argument :description_widget,
          ::Types::WorkItems::Widgets::DescriptionInputType,
          required: false,
          description: 'Input for description widget.'
        argument :milestone_widget,
          ::Types::WorkItems::Widgets::MilestoneInputType,
          required: false,
          description: 'Input for milestone widget.'
      end
    end
  end
end
