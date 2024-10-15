# frozen_string_literal: true

require_relative '../../tooling/danger/ai_logging'

module Danger
  class AiLogging < ::Danger::Plugin
    # Include the helper code
    include Tooling::Danger::AiLogging
  end
end
