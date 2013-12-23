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
      
      # Sort by :sort param
      @issues = sort(@issues, params[:sort])

      @issues
    end

    private

    def sort(issues, condition)
      case condition
      when 'newest' then issues.except(:order).order('created_at DESC')
      when 'oldest' then issues.except(:order).order('created_at ASC')
      when 'recently_updated' then issues.except(:order).order('updated_at DESC')
      when 'last_updated' then issues.except(:order).order('updated_at ASC')
      when 'milestone_due_soon' then issues.except(:order).joins(:milestone).order("milestones.due_date ASC")
      when 'milestone_due_later' then issues.except(:order).joins(:milestone).order("milestones.due_date DESC")
      else issues
      end
    end

  end
end
