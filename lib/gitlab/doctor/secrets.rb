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
          models_with_attributes[model] += model.encrypted_attributes.keys
        end

        models_with_encrypted_tokens.each do |model|
          models_with_attributes[model] += model.encrypted_token_authenticatable_fields
        end

        check_model_attributes(models_with_attributes)

        logger.info "Done!"
      end

      private

      def check_model_attributes(models_with_attributes)
        running_failures = 0

        models_with_attributes.each do |model, attributes|
          failures_per_row = Hash.new { |h, k| h[k] = [] }
          model.find_each do |data|
            attributes.each do |att|
              failures_per_row[data.id] << att unless valid_attribute?(data, att)
            end
          end

          running_failures += failures_per_row.keys.count
          output_failures_for_model(model, failures_per_row)
        end

        logger.info "Total: #{running_failures} row(s) affected".color(:blue)
      end

      def output_failures_for_model(model, failures)
        status_color = failures.empty? ? :green : :red

        logger.info "- #{model} failures: #{failures.count}".color(status_color)
        failures.each do |row_id, attributes|
          logger.debug "  - #{model}[#{row_id}]: #{attributes.join(", ")}".color(:red)
        end
      end

      def models_with_encrypted_attributes
        all_models.select { |d| d.encrypted_attributes.present? }
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
        data.public_send(attr) # rubocop:disable GitlabSecurity/PublicSend

        true
      rescue OpenSSL::Cipher::CipherError, TypeError
        false
      rescue StandardError => e
        logger.debug "> Something went wrong for #{data.class.name}[#{data.id}].#{attr}: #{e}".color(:red)

        false
      end
    end
  end
end
