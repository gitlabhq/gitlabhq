module Boards
  class BaseService < ::BaseService
    delegate :board, to: :project
  end
end
