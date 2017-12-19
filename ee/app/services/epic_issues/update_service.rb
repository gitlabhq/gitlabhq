module EpicIssues
  class UpdateService < BaseService
    attr_reader :epic_issue, :current_user, :old_position, :params

    def initialize(epic_issue, user, params)
      @epic_issue = epic_issue
      @current_user = user
      @old_position = epic_issue.position
      @params = params
    end

    def execute
      move_issue if params[:position]
      success
    end

    private

    def move_issue
      epic_issue.update_attribute(:position, new_position)
      issues_to_move.update_all("position = position #{update_operator} 1")
    end

    def epic
      @epic ||= epic_issue.epic
    end

    def issues_to_move
      @issues_to_move ||= epic.epic_issues
        .where('position >= ? AND position <= ? AND id != ?', from, to, epic_issue.id)
        .order(:position)
    end

    def from
      [new_position, old_position].min
    end

    def to
      [new_position, old_position].max
    end

    def update_operator
      new_position > old_position ? '-' : '+'
    end

    def new_position
      @new_position ||= begin
        replacing_issue = epic.epic_issues.order(:position).limit(1).offset(params[:position])[0]
        replacing_issue.position
      end
    end
  end
end
