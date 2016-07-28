module Boards
  class CreateService
    def initialize(project)
      @project = project
    end

    def execute
      create_board! unless project.board.present?
      project.board
    end

    private

    attr_reader :project

    def create_board!
      project.create_board
      project.board.lists.create(list_type: :backlog, position: 0)
      project.board.lists.create(list_type: :done, position: 1)
    end
  end
end
