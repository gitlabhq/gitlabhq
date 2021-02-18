# frozen_string_literal: true

module Terraform
  class StatesFinder
    def initialize(project, current_user, params: {})
      @project = project
      @current_user = current_user
      @params = params
    end

    def execute
      return ::Terraform::State.none unless can_read_terraform_states?

      states = project.terraform_states
      states = states.with_name(params[:name]) if params[:name].present?

      states.ordered_by_name
    end

    private

    attr_reader :project, :current_user, :params

    def can_read_terraform_states?
      current_user.can?(:read_terraform_state, project)
    end
  end
end
