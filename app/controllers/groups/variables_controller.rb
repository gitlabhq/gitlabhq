# frozen_string_literal: true

module Groups
  class VariablesController < Groups::ApplicationController
    before_action :authorize_admin_group!

    skip_cross_project_access_check :show, :update

    feature_category :pipeline_authoring

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
      params.permit(variables_attributes: [*variable_params_attributes])
    end

    def variable_params_attributes
      %i[id variable_type key secret_value protected masked _destroy]
    end

    def authorize_admin_build!
      return render_404 unless can?(current_user, :admin_build, group)
    end
  end
end

Groups::VariablesController.prepend_mod_with('Groups::VariablesController')
