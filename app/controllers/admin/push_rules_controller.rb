class Admin::PushRulesController < Admin::ApplicationController
  before_action :push_rule

  respond_to :html

  def index
  end

  def update
    @push_rule.update_attributes(push_rule_params.merge(is_sample: true))

    if @push_rule.valid?
      redirect_to admin_push_rules_path, notice: 'Push Rules updated successfully.'
    else
      render :index
    end
  end

  private

  def push_rule_params
    params.require(:push_rule).permit(:deny_delete_tag, :delete_branch_regex,
      :commit_message_regex, :force_push_regex, :author_email_regex, :member_check, :file_name_regex, :max_file_size)
  end

  def push_rule
    @push_rule ||= PushRule.find_or_create_by(is_sample: true)
  end
end
