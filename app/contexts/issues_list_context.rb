class IssuesListContext < BaseContext
  include IssuesHelper

  attr_accessor :issues

  def execute
    @issues = case params[:status]
              when issues_filter[:all] then @project.issues
              when issues_filter[:closed] then @project.issues.closed
              when issues_filter[:to_me] then @project.issues.opened.assigned(current_user)
              else @project.issues.opened
              end

    @issues = @issues.tagged_with(params[:label_name]) if params[:label_name].present?
    @issues = @issues.includes(:author, :project).order("updated_at")

    # Filter by specific assignee_id (or lack thereof)?
    if params[:assignee_id].present?
      @issues = @issues.where(assignee_id: (params[:assignee_id] == '0' ? nil : params[:assignee_id]))
    end

    # Filter by specific milestone_id (or lack thereof)?
    if params[:milestone_id].present?
      @issues = @issues.where(milestone_id: (params[:milestone_id] == '0' ? nil : params[:milestone_id]))
    end

    @issues
  end
end
