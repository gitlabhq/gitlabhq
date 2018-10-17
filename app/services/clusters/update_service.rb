# frozen_string_literal: true

module Clusters
  class UpdateService
    attr_reader :current_user, :params

    def initialize(user = nil, params = {})
      @current_user, @params = user, params.dup
    end

    def execute(cluster)
      cluster.update(params)
    end
  end
end
