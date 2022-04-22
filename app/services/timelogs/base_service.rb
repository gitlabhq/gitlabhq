# frozen_string_literal: true

module Timelogs
  class BaseService
    include BaseServiceUtility
    include Gitlab::Utils::StrongMemoize

    attr_accessor :timelog, :current_user

    def initialize(timelog, user)
      @timelog = timelog
      @current_user = user
    end
  end
end
