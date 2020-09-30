# frozen_string_literal: true

module Resolvers
  module Terraform
    class StatesResolver < BaseResolver
      type Types::Terraform::StateType, null: true

      alias_method :project, :object

      def resolve(**args)
        return ::Terraform::State.none unless can_read_terraform_states?

        project.terraform_states.ordered_by_name
      end

      private

      def can_read_terraform_states?
        current_user.can?(:read_terraform_state, project)
      end
    end
  end
end
