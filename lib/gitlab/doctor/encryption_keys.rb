# frozen_string_literal: true

require 'base64'

module Gitlab
  module Doctor
    class EncryptionKeys
      attr_reader :logger

      PRINT_PROGRESS_EVERY = 1000
      KEY_TYPES = Gitlab::Encryption::KeyProvider::KEY_PROVIDERS.keys.grep(/active_record/)
      Key = Struct.new(:type, :id, :truncated_secret)

      def initialize(logger)
        @logger = logger
      end

      def run!
        logger.info "Gathering existing encryption keys:"
        known_keys.each do |key|
          logger.info "- #{key.type}: ID => `#{key.id}`; truncated secret => `#{key.truncated_secret}`"
        end
        logger.info "\n"

        logger.info "Gathering encryption keys for models with Active Record Encryption attributes"
        Rails.application.eager_load!

        encryption_keys_usage_per_model =
          models_with_encrypted_attributes.index_with do |model|
            gather_encryption_keys(model)
          end

        encryption_keys_usage_per_model.each do |model, encryption_keys_usage|
          logger.info "Encryption keys usage for #{model.name}:#{' NONE' if encryption_keys_usage.empty?}"
          encryption_keys_usage.each do |key, count|
            logger.info "- `#{key}`#{' (UNKNOWN KEY!)' unless known_keys.map(&:id).include?(key)} => #{count}"
          end
        end
      end

      private

      def known_keys
        @known_keys ||= KEY_TYPES.each_with_object([]) do |key_type, memo|
          Gitlab::Encryption::KeyProvider[key_type].decryption_keys.each do |key|
            memo << Key.new(key_type, key.id)
          end
        end.tap do |keys| # rubocop:disable Style/MultilineBlockChain -- avoid a local instance
          populate_actual_secrets!(keys)
        end
      end

      def populate_actual_secrets!(keys)
        KEY_TYPES.each do |key_type|
          actual_secrets = Gitlab::Encryption::KeyProvider::KEY_PROVIDERS[key_type].secrets.call

          keys.select { |k| k.type == key_type }.each_with_index do |key, index|
            key.truncated_secret = "#{actual_secrets[index][...3]}...#{actual_secrets[index][-3..]}"
          end
        end
      end

      def gather_encryption_keys(model)
        encrypted_attributes = model.encrypted_attributes
        total_count = model.count
        return {} if total_count == 0

        encryption_keys_usage = Hash.new { |hash, key| hash[key] = 0 }

        model.find_each.with_index do |instance, index|
          encrypted_attributes.each do |attribute_name|
            encryption_keys_usage[encryption_key(instance, attribute_name)] += 1
          end

          logger.info "Checked #{index + 1}/#{total_count} #{model.name.pluralize}" if index % PRINT_PROGRESS_EVERY == 0
        end
        logger.info "Checked #{total_count} #{model.name.pluralize}\n"

        encryption_keys_usage
      end

      def encryption_key(instance, attribute_name)
        Base64.decode64(Gitlab::Json.parse(instance.ciphertext_for(attribute_name))['h']['i'])
      end

      def models_with_encrypted_attributes
        ApplicationRecord.descendants.select { |d| d.encrypted_attributes.present? }
      end
    end
  end
end
