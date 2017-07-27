module Boards
  class ListService < BaseService
    prepend EE::Boards::ListService

    def execute
      create_board! if project.boards.empty?
      project.boards
    end

    private

    def create_board!
      Boards::CreateService.new(project, current_user).execute
    end
  end
end
