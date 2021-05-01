# frozen_string_literal: true

module Services
  # adapter for existing services over BaseServiceUtility - add error and
  # success methods returning ServiceResponse objects
  module ReturnServiceResponses
    def error(message, http_status, pass_back: {})
      ServiceResponse.error(message: message, http_status: http_status, payload: pass_back)
    end

    def success(payload)
      ServiceResponse.success(payload: payload)
    end
  end
end
