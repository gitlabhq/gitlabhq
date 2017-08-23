module EE
  # Issue position on list boards should be relative to all group projects
  module RelativePositioning
    extend ActiveSupport::Concern

    def board_group
      @group ||= project.group
    end

    def has_group_boards?
      board_group && board_group.boards.any?
    end

    def project_ids
      if has_group_boards?
        board_group.projects.pluck(:id)
      else
        super
      end
    end
  end
end
