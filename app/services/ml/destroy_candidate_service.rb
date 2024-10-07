# frozen_string_literal: true

module Ml
  class DestroyCandidateService
    def initialize(candidate, user)
      @candidate = candidate
      @user = user
    end

    def execute
      if @candidate.destroy
        ServiceResponse.success(payload: payload)
      else
        ServiceResponse.error(message: @candidate.errors.full_messages, payload: payload)
      end
    end

    private

    def payload
      { candidate: @candidate }
    end
  end
end
