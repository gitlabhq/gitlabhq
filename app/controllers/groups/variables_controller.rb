module Groups
  class VariablesController < Groups::ApplicationController
    before_action :variable, only: [:show, :update, :destroy]
    before_action :authorize_admin_build!

    def index
      redirect_to group_settings_ci_cd_path(group)
    end

    def show
    end

    def update
      if variable.update(group_params)
        redirect_to group_variables_path(group),
                    notice: 'Variable was successfully updated.'
      else
        render "show"
      end
    end

    def create
      new_variable = group.variables.create(group_params)

      if new_variable.persisted?
        redirect_to group_settings_ci_cd_path(group),
                    notice: 'Variables were successfully updated.'
      else
        @variable = new_variable.present(current_user: current_user)
        render "show"
      end
    end

    def destroy
      if variable.destroy
        redirect_to group_settings_ci_cd_path(group),
                    status: 302,
                    notice: 'Variable was successfully removed.'
      else
        redirect_to group_settings_ci_cd_path(group),
                    status: 302,
                    notice: 'Failed to remove the variable'
      end
    end

    private

    def authorize_admin_build!
      return render_404 unless can?(current_user, :admin_build, group)
    end

    def group_params
      params.require(:variable).permit([:key, :value, :protected])
    end

    def variable
      @variable ||= group.variables.find(params[:id]).present(current_user: current_user)
    end
  end
end
