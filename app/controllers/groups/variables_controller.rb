module Groups
  class VariablesController < Groups::ApplicationController
    before_action :authorize_admin_build!

    def show
      respond_to do |format|
        format.json do
          render status: :ok, json: { variables: GroupVariableSerializer.new.represent(@group.variables) }
        end
      end
    end

    def update
      if @group.update(variables_params)
        respond_to do |format|
          format.json { return render status: :ok, json: { variables: GroupVariableSerializer.new.represent(@group.variables) } }
        end
      else
        respond_to do |format|
          format.json { render status: :bad_request, json: @group.errors.full_messages }
        end
      end
    end

    private

    def variables_params
      params.permit(variables_attributes: [*variable_params_attributes])
    end

    def variable_params_attributes
      %i[id key value protected _destroy]
    end

    def authorize_admin_build!
      return render_404 unless can?(current_user, :admin_build, group)
    end
  end
end
