module Issues
  class ListContext < BaseContext
    attr_accessor :issues

    def execute
      @issues = @project.issues

      @issues = case params[:state]
                when 'all' then @issues
                when 'closed' then @issues.closed
                else @issues.opened
                end

      @issues = case params[:scope]
                when 'assigned-to-me' then @issues.assigned_to(current_user)
                when 'created-by-me' then @issues.authored(current_user)
                else @issues
                end

      @issues = @issues.tagged_with(params[:label_name]) if params[:label_name].present?
      @issues = @issues.includes(:author, :project)

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
end
