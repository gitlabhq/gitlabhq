# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        module File
          class Base
            include Gitlab::Utils::StrongMemoize

            attr_reader :location, :opts, :errors

            YAML_WHITELIST_EXTENSION = /.+\.(yml|yaml)$/i.freeze

            def initialize(location, opts = {})
              @location = location
              @opts = opts
              @errors = []

              validate!
            end

            def invalid_extension?
              !::File.basename(location).match(YAML_WHITELIST_EXTENSION)
            end

            def valid?
              errors.none?
            end

            def error_message
              errors.first
            end

            def content
              raise NotImplementedError, 'subclass must implement fetching raw content'
            end

            def to_hash
              @hash ||= Ci::Config::Loader.new(content).load!
            rescue Ci::Config::Loader::FormatError
              nil
            end

            protected

            def validate!
              validate_location!
              validate_content! if errors.none?
              validate_hash! if errors.none?
            end

            def validate_location!
              if invalid_extension?
                errors.push("Included file `#{location}` does not have YAML extension!")
              end
            end

            def validate_content!
              if content.blank?
                errors.push("Included file `#{location}` is empty or does not exist!")
              end
            end

            def validate_hash!
              if to_hash.blank?
                errors.push("Included file `#{location}` does not have valid YAML syntax!")
              end
            end
          end
        end
      end
    end
  end
end
