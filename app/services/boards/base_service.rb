module Boards
  class BaseService
    def initialize(project, user, params = {})
      @project = project
      @board = project.board
      @user = user
      @params = params.dup
    end

    private

    attr_reader :project, :board, :user, :params
  end
end
