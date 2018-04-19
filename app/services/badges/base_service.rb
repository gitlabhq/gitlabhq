module Badges
  class BaseService
    protected

    attr_accessor :params

    def initialize(params = {})
      @params = params.dup
    end
  end
end
