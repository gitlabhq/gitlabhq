# frozen_string_literal: true

module Groups
  class ClustersController < Groups::ApplicationController
    def index
      @clusters = []
    end
  end
end
