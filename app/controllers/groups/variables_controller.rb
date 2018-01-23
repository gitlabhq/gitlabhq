module Groups
  class VariablesController < Groups::ApplicationController
    before_action :authorize_admin_build!

    def save_multiple
      respond_to do |format|
        format.json do
          return head :ok if @group.update(variables_params)

          head :bad_request
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
