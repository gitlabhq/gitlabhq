# frozen_string_literal: true

module Gitlab
  module Config
    module Loader
      class MultiDocYaml
        TooManyDocumentsError = Class.new(Loader::FormatError)
        DataTooLargeError = Class.new(Loader::FormatError)
        NotHashError = Class.new(Loader::FormatError)

        MULTI_DOC_DIVIDER = /^---$/.freeze

        def initialize(config, max_documents:, additional_permitted_classes: [])
          @max_documents = max_documents
          @safe_config = load_config(config, additional_permitted_classes)
        end

        def load!
          raise TooManyDocumentsError, 'The parsed YAML has too many documents' if too_many_documents?
          raise DataTooLargeError, 'The parsed YAML is too big' if too_big?
          raise NotHashError, 'Invalid configuration format' unless all_hashes?

          safe_config.map(&:deep_symbolize_keys)
        end

        private

        attr_reader :safe_config, :max_documents

        def load_config(config, additional_permitted_classes)
          config.split(MULTI_DOC_DIVIDER).filter_map do |document|
            YAML.safe_load(document,
              permitted_classes: [Symbol, *additional_permitted_classes],
              permitted_symbols: [],
              aliases: true
            )
          end
        rescue Psych::Exception => e
          raise Loader::FormatError, e.message
        end

        def all_hashes?
          safe_config.all?(Hash)
        end

        def too_many_documents?
          safe_config.count > max_documents
        end

        def too_big?
          !deep_sizes.all?(&:valid?)
        end

        def deep_sizes
          safe_config.map do |config|
            Gitlab::Utils::DeepSize.new(config,
              max_size: Gitlab::CurrentSettings.current_application_settings.max_yaml_size_bytes,
              max_depth: Gitlab::CurrentSettings.current_application_settings.max_yaml_depth)
          end
        end
      end
    end
  end
end
