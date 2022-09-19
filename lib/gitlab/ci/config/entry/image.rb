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
            validates :config, allowed_keys: IMAGEABLE_ALLOWED_KEYS
          end

          def value
            if string?
              { name: @config }
            elsif hash?
              {
                name: @config[:name],
                entrypoint: @config[:entrypoint],
                ports: (ports_value if ports_defined?),
                pull_policy: pull_policy_value
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
