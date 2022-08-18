# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a Docker image.
        #
        class Image < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Ci::Config::Entry::Imageable

          validations do
            validates :config, allowed_keys: IMAGEABLE_ALLOWED_KEYS,
                               if: :ci_docker_image_pull_policy_enabled?
            validates :config, allowed_keys: IMAGEABLE_LEGACY_ALLOWED_KEYS,
                               unless: :ci_docker_image_pull_policy_enabled?
          end

          def value
            if string?
              { name: @config }
            elsif hash?
              {
                name: @config[:name],
                entrypoint: @config[:entrypoint],
                ports: (ports_value if ports_defined?),
                pull_policy: (ci_docker_image_pull_policy_enabled? ? pull_policy_value : nil)
              }.compact
            else
              {}
            end
          end
        end
      end
    end
  end
end
