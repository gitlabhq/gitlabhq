# frozen_string_literal: true

module Gitlab
  module SlashCommands
    module Presenters
      class Error < Presenters::Base
        def initialize(message)
          @message = message
        end

        def message
          ephemeral_response(text: @message)
        end
      end
    end
  end
end
