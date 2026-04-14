# frozen_string_literal: true

module Labels
  class DestroyService < Labels::BaseService
    attr_reader :current_user, :label

    def initialize(current_user, label)
      @current_user = current_user
      @label = label
    end

    def execute
      @label.destroy
      @label
    end
  end
end

Labels::DestroyService.prepend_mod
