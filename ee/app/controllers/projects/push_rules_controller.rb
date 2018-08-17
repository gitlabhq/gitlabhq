class Projects::PushRulesController < Projects::ApplicationController
  include RepositorySettingsRedirect

  # Authorize
  before_action :authorize_admin_project!
  before_action :check_push_rules_available!

  respond_to :html

  layout "project_settings"

  def update
    @push_rule = project.push_rule
    @push_rule.update(push_rule_params)

    if @push_rule.valid?
      flash[:notice] = 'Push Rules updated successfully.'
    else
      flash[:alert] = @push_rule.errors.full_messages.join(', ').html_safe
    end

    redirect_to_repository_settings(@project, anchor: 'js-push-rules')
  end

  private

  # Only allow a trusted parameter "white list" through.
  def push_rule_params
    allowed_fields = %i[deny_delete_tag delete_branch_regex commit_message_regex commit_message_negative_regex
                        branch_name_regex force_push_regex author_email_regex
                        member_check file_name_regex max_file_size prevent_secrets]

    if can?(current_user, :change_reject_unsigned_commits, project)
      allowed_fields << :reject_unsigned_commits
    end

    if can?(current_user, :change_commit_committer_check, project)
      allowed_fields << :commit_committer_check
    end

    params.require(:push_rule).permit(allowed_fields)
  end
end
