class Projects::PushRulesController < Projects::ApplicationController
  # Authorize
  before_action :authorize_admin_project!

  respond_to :html

  layout "project_settings"

  def index
    project.create_push_rule unless project.push_rule

    @push_rule = project.push_rule
  end

  def update
    @push_rule = project.push_rule
    @push_rule.update_attributes(push_rule_params)

    if @push_rule.valid?
      redirect_to namespace_project_push_rules_path(@project.namespace, @project), notice: 'Push Rules updated successfully.'
    else
      render :index
    end
  end

  private

  # Only allow a trusted parameter "white list" through.
  def push_rule_params
    params.require(:push_rule).permit(:deny_delete_tag, :delete_branch_regex,
      :commit_message_regex, :force_push_regex, :author_email_regex, :member_check, :file_name_regex, :max_file_size)
  end
end
