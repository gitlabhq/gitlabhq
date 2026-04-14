# frozen_string_literal: true

module Gitlab
  module Redis
    class ActionCable < ::Gitlab::Redis::Wrapper
      class << self
        # The data we store on ActionCable used to be stored on SharedState.
        def config_fallback
          SharedState
        end

        def active?
          return super if config_file_name

          false
        end
      end
    end
  end
end
