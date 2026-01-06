# frozen_string_literal: true

require_relative "disable_joins/configurable"

module ActiveRecord
  module GitlabPatches
    module DisableJoins
      ActiveSupport.on_load(:active_record) do
        # Extend `disable_joins` to accept Proc
        ::ActiveRecord::Associations::Association.prepend(
          ActiveRecord::GitlabPatches::DisableJoins::Configurable
        )
      end
    end
  end
end
