# frozen_string_literal: true

module Ide
  class TerminalConfigService < ::Ide::BaseConfigService
    private

    def success(pass_back = {})
      result = super(pass_back)
      result[:terminal] = config.terminal_value
      result
    end
  end
end
