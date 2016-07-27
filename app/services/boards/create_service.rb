module Boards
  class CreateService
    def initialize(project)
      @project = project
    end

    def execute
      if project.board.present?
        project.board
      else
        project.create_board
      end
    end

    private

    attr_reader :project
  end
end
