module MilestoneActions
  extend ActiveSupport::Concern

  def merge_requests
    respond_to do |format|
      format.json do
        render json: tabs_json("shared/milestones/_merge_requests_tab", {
          merge_requests: @milestone.merge_requests,
          show_project_name: true
        })
      end
    end
  end

  def participants
    respond_to do |format|
      format.json do
        render json: tabs_json("shared/milestones/_participants_tab", {
          users: @milestone.participants
        })
      end
    end
  end

  def labels
    respond_to do |format|
      format.json do
        render json: tabs_json("shared/milestones/_labels_tab", {
          labels: @milestone.labels
        })
      end
    end
  end

  private

  def tabs_json(partial, data = {})
    {
      html: view_to_html_string(partial, data)
    }
  end
end
