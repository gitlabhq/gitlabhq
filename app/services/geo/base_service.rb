module Geo
  class BaseService
    def initialize
      @queue = Gitlab::Geo::UpdateQueue.new
    end
  end
end
