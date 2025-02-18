# frozen_string_literal: true

module Groups
  class VariablesController < Groups::ApplicationController
    before_action :authorize_admin_group!, except: :update
    before_action :authorize_admin_cicd_variables!, only: :update

    skip_cross_project_access_check :show, :update

    feature_category :ci_variables

    urgency :low, [:show]

    def show
      respond_to do |format|
        format.json do
          render status: :ok, json: { variables: ::Ci::GroupVariableSerializer.new.represent(@group.variables) }
        end
      end
    end

    def update
      update_result = Ci::ChangeVariablesService.new(
        container: @group, current_user: current_user,
        params: group_variables_params
      ).execute

      if update_result
        respond_to do |format|
          format.json { render_group_variables }
        end
      else
        respond_to do |format|
          format.json { render_error }
        end
      end
    end

    private

    def render_group_variables
      render status: :ok, json: { variables: ::Ci::GroupVariableSerializer.new.represent(@group.variables) }
    end

    def render_error
      render status: :bad_request, json: @group.errors.full_messages
    end

    def group_variables_params
      params.permit(variables_attributes: Array(variable_params_attributes))
    end

    def variable_params_attributes
      %i[id variable_type key description secret_value protected masked hidden raw _destroy]
    end
  end
end

Groups::VariablesController.prepend_mod_with('Groups::VariablesController')
