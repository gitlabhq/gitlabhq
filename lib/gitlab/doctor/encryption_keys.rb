# frozen_string_literal: true

module Gitlab
  module Doctor
    class EncryptionKeys
      attr_reader :logger

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

        encrypted_attributes.each do |attribute_name|
          encryption_keys(model, attribute_name).each do |key_id, count|
            encryption_keys_usage[key_id] += count
          end
        end
        logger.info "Checked #{total_count} #{model.name}"

        encryption_keys_usage
      end

      def encryption_keys(model, attr)
        Hash[
          model
            .connection
            .execute(
              <<~SQL
              SELECT #{attr}->'h'->'i' as key_id, COUNT(*) as usage_count
              FROM #{model.table_name}
              WHERE #{attr} IS NOT NULL
              GROUP BY key_id
              SQL
            )
            .filter_map { |a| a['key_id'] && [a['key_id'] && Base64.decode64(a['key_id']), a['usage_count']] }
        ]
      end

      def models_with_encrypted_attributes
        Gitlab::Database.database_base_models.values.flat_map do |klass|
          klass.descendants.select { |d| d.encrypted_attributes.present? }
        end
      end
    end
  end
end
