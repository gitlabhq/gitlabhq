# frozen_string_literal: true

module Gitlab
  module Doctor
    class ResetTokens
      attr_reader :logger

      PRINT_PROGRESS_EVERY = 1000

      def initialize(logger, model_names:, token_names:, dry_run: true)
        @logger = logger
        @model_names = model_names
        @token_names = token_names
        @dry_run = dry_run
      end

      def run!
        logger.info "Resetting #{@token_names.join(', ')} on #{@model_names.join(', ')} if they can not be read"
        logger.info "Executing in DRY RUN mode, no records will actually be updated" if @dry_run
        Rails.application.eager_load!

        models_with_encrypted_tokens.each do |model|
          fix_model(model)
        end
        logger.info "Done!"
      end

      private

      def fix_model(model)
        matched_token_names = @token_names & model.encrypted_token_authenticatable_fields.map(&:to_s)

        return if matched_token_names.empty?

        total_count = model.count

        model.find_each.with_index do |instance, index|
          matched_token_names.each do |attribute_name|
            fix_attribute(instance, attribute_name)
          end

          logger.info "Checked #{index + 1}/#{total_count} #{model.name.pluralize}" if index % PRINT_PROGRESS_EVERY == 0
        end
        logger.info "Checked #{total_count} #{model.name.pluralize}"
      end

      def fix_attribute(instance, attribute_name)
        instance.public_send(attribute_name) # rubocop:disable GitlabSecurity/PublicSend
      rescue OpenSSL::Cipher::CipherError, TypeError
        logger.debug "> Fix #{instance.class.name}[#{instance.id}].#{attribute_name}"
        instance.public_send("reset_#{attribute_name}!") unless @dry_run # rubocop:disable GitlabSecurity/PublicSend
      rescue StandardError => e
        logger.debug(
          Rainbow("> Something went wrong for #{instance.class.name}[#{instance.id}].#{attribute_name}: #{e}").red)

        false
      end

      def models_with_encrypted_tokens
        ApplicationRecord.descendants.select do |model|
          @model_names.include?(model.name) && model.include?(TokenAuthenticatable)
        end
      end
    end
  end
end
