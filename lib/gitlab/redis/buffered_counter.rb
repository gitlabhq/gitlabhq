# frozen_string_literal: true

module Gitlab
  module Redis
    class BufferedCounter < ::Gitlab::Redis::Wrapper
      class << self
        def config_fallback
          SharedState
        end

        def params
          # This avoid using Gitlab::Instrumentation::Redis::BufferedCounter since this class is a temporary
          # helper for migration. The redis commands should be tracked under the label of `storage: shared_state`.
          super.merge({ instrumentation_class: ::Gitlab::Instrumentation::Redis::SharedState })
        end
      end
    end
  end
end
