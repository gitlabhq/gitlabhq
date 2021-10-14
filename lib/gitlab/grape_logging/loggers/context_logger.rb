# frozen_string_literal: true

# This class adds application context to the grape logger
module Gitlab
  module GrapeLogging
    module Loggers
      class ContextLogger < ::GrapeLogging::Loggers::Base
        def parameters(request, _)
          # Add remote_ip if this request wasn't already handled. If we
          # add it unconditionally we can break client_id due to the way
          # the context inherits the user.
          unless Gitlab::ApplicationContext.current_context_include?(:remote_ip)
            Gitlab::ApplicationContext.push(remote_ip: request.ip)
          end

          Gitlab::ApplicationContext.current
        end
      end
    end
  end
end
