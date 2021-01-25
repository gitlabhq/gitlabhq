# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Credentials
        module Registry
          class DependencyProxy < GitlabRegistry
            def url
              "#{Gitlab.config.gitlab.host}:#{Gitlab.config.gitlab.port}"
            end

            def valid?
              Gitlab.config.dependency_proxy.enabled
            end
          end
        end
      end
    end
  end
end
