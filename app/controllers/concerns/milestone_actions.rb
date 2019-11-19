# frozen_string_literal: true

module MilestoneActions
  extend ActiveSupport::Concern

  def merge_requests
    respond_to do |format|
      format.html { redirect_to milestone_redirect_path }
      format.json do
        render json: tabs_json("shared/milestones/_merge_requests_tab", {
          merge_requests: @milestone.sorted_merge_requests(current_user), # rubocop:disable Gitlab/ModuleWithInstanceVariables
          show_project_name: true
        })
      end
    end
  end

  def participants
    respond_to do |format|
      format.html { redirect_to milestone_redirect_path }
      format.json do
        render json: tabs_json("shared/milestones/_participants_tab", {
          users: @milestone.issue_participants_visible_by_user(current_user) # rubocop:disable Gitlab/ModuleWithInstanceVariables
        })
      end
    end
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def labels
    respond_to do |format|
      format.html { redirect_to milestone_redirect_path }
      format.json do
        milestone_labels = @milestone.issue_labels_visible_by_user(current_user)

        render json: tabs_json("shared/milestones/_labels_tab", {
          labels: milestone_labels.map do |label|
            label.present(issuable_subject: @milestone.resource_parent)
          end
        })
      end
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  private

  def tabs_json(partial, data = {})
    {
      html: view_to_html_string(partial, data)
    }
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def milestone_redirect_path
    if @milestone.global_milestone?
      url_for(action: :show, title: @milestone.title)
    else
      url_for(action: :show)
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables
end
