# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Credentials
        class Factory
          def initialize(build)
            @build = build
          end

          def create!
            credentials.select(&:valid?)
          end

          private

          def credentials
            providers.map { |provider| provider.new(@build) }
          end

          def providers
            [Registry::GitlabRegistry, Registry::DependencyProxy]
          end
        end
      end
    end
  end
end
