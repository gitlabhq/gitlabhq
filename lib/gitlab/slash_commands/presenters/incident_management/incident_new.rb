# frozen_string_literal: true

module Gitlab
  module SlashCommands
    module Presenters
      module IncidentManagement
        class IncidentNew < Presenters::Base
          def present(message)
            ephemeral_response(text: message)
          end
        end
      end
    end
  end
end
