# frozen_string_literal: true

module Organizations
  class BaseService
    include BaseServiceUtility

    attr_reader :current_user, :params

    def initialize(current_user: nil, params: {})
      @current_user = current_user
      @params = params.dup
    end
  end
end
