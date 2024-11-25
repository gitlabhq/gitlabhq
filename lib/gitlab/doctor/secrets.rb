# frozen_string_literal: true

module Gitlab
  module Doctor
    class Secrets
      attr_reader :logger

      def initialize(logger)
        @logger = logger
      end

      def run!
        logger.info "Checking encrypted values in the database"
        Rails.application.eager_load! unless Rails.application.config.eager_load

        models_with_attributes = Hash.new { |h, k| h[k] = [] }

        models_with_encrypted_attributes.each do |model|
          models_with_attributes[model] += model.attr_encrypted_attributes.keys
        end

        models_with_encrypted_tokens.each do |model|
          models_with_attributes[model] += model.encrypted_token_authenticatable_fields
        end

        check_model_attributes(models_with_attributes)

        logger.info "Done!"
      end

      private

      # Skipping initializers may be needed if those attempt to access
      # encrypted data on initialization and could fail because of it.
      #
      # format example:
      # {
      #   model_class => {
      #     [
      #       { action: :create, filters: [:before, :filter_name1] },
      #       { action: :update, filters: [:after,  :filter_name2] }
      #     ]
      #   }
      # }
      MODEL_INITIALIZERS_TO_SKIP = {
        Integration => [
          { action: :initialize, filters: [:after, :initialize_properties] }
        ]
      }.freeze

      def check_model_attributes(models_with_attributes)
        running_failures = 0

        models_with_attributes.each do |model, attributes|
          failures_per_row = Hash.new { |h, k| h[k] = [] }

          with_skipped_callbacks_for(model) do
            model.find_each do |data|
              attributes.each do |att|
                failures_per_row[data.id] << att unless valid_attribute?(data, att)
              end
            end
          end

          running_failures += failures_per_row.keys.count
          output_failures_for_model(model, failures_per_row)
        end

        logger.info Rainbow("Total: #{running_failures} row(s) affected").blue
      end

      def output_failures_for_model(model, failures)
        status_color = failures.empty? ? :green : :red

        logger.info Rainbow("- #{model} failures: #{failures.count}").color(status_color)
        failures.each do |row_id, attributes|
          logger.debug Rainbow("  - #{model}[#{row_id}]: #{attributes.join(', ')}").red
        end
      end

      def models_with_encrypted_attributes
        all_models.select { |d| d.attr_encrypted_attributes.present? }
      end

      def models_with_encrypted_tokens
        all_models.select do |d|
          d.include?(TokenAuthenticatable) && d.encrypted_token_authenticatable_fields.present?
        end
      end

      def all_models
        @all_models ||= ApplicationRecord.descendants
      end

      def valid_attribute?(data, attr)
        data.send(attr) # rubocop:disable GitlabSecurity/PublicSend

        true
      rescue OpenSSL::Cipher::CipherError, TypeError
        false
      rescue StandardError => e
        logger.debug Rainbow("> Something went wrong for #{data.class.name}[#{data.id}].#{attr}: #{e}").red

        false
      end

      # WARNING: using this logic in other places than a Rake task will need a
      # different approach, as simply setting the callback again is not thread-safe
      def with_skipped_callbacks_for(model)
        raise StandardError, 'can only be used in a Rake environment' unless Gitlab::Runtime.rake?

        skip_callbacks_for_model(model)

        yield

        skip_callbacks_for_model(model, reset: true)
      end

      def skip_callbacks_for_model(model, reset: false)
        MODEL_INITIALIZERS_TO_SKIP.each do |klass, initializers|
          next unless model <= klass

          initializers.each do |initializer|
            if reset
              model.set_callback(initializer[:action], *initializer[:filters])
            else
              model.skip_callback(initializer[:action], *initializer[:filters])
            end
          end
        end
      end
    end
  end
end
