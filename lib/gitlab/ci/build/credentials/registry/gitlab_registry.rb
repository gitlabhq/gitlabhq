# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Credentials
        module Registry
          class GitlabRegistry < Credentials::Base
            attr_reader :username, :password

            def initialize(build)
              @username = Gitlab::Auth::CI_JOB_USER
              @password = build.token
            end

            def url
              Gitlab.config.registry.host_port
            end

            def valid?
              Gitlab.config.registry.enabled
            end

            def type
              'registry'
            end
          end
        end
      end
    end
  end
end
