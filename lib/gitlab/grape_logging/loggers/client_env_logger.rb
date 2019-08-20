# frozen_string_literal: true

# This is a fork of
# https://github.com/aserafin/grape_logging/blob/master/lib/grape_logging/loggers/client_env.rb
# to use remote_ip instead of ip.
module Gitlab
  module GrapeLogging
    module Loggers
      class ClientEnvLogger < ::GrapeLogging::Loggers::Base
        def parameters(request, _)
          { remote_ip: request.env["HTTP_X_FORWARDED_FOR"] || request.env["REMOTE_ADDR"], ua: request.env["HTTP_USER_AGENT"] }
        end
      end
    end
  end
end
