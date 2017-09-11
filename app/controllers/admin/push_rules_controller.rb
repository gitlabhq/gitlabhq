class Admin::PushRulesController < Admin::ApplicationController
  before_action :check_push_rules_available!
  before_action :push_rule

  respond_to :html

  def show
  end

  def update
    @push_rule.update_attributes(push_rule_params)

    if @push_rule.valid?
      redirect_to admin_push_rule_path, notice: 'Push Rule updated successfully.'
    else
      render :show
    end
  end

  private

  def check_push_rules_available!
    render_404 unless License.feature_available?(:push_rules)
  end

  def push_rule_params
    params.require(:push_rule).permit(:deny_delete_tag, :delete_branch_regex,
      :commit_message_regex, :branch_name_regex, :force_push_regex, :author_email_regex, :member_check,
      :file_name_regex, :max_file_size, :prevent_secrets)
  end

  def push_rule
    @push_rule ||= PushRule.find_or_create_by(is_sample: true)
  end
end
