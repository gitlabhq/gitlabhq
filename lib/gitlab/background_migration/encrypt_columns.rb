# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # EncryptColumn migrates data from an unencrypted column - `foo`, say - to
    # an encrypted column - `encrypted_foo`, say.
    #
    # To avoid depending on a particular version of the model in app/, add a
    # model to `lib/gitlab/background_migration/models/encrypt_columns` and use
    # it in the migration that enqueues the jobs, so code can be shared.
    #
    # For this background migration to work, the table that is migrated _has_ to
    # have an `id` column as the primary key. Additionally, the encrypted column
    # should be managed by attr_encrypted, and map to an attribute with the same
    # name as the unencrypted column (i.e., the unencrypted column should be
    # shadowed), unless you want to define specific methods / accessors in the
    # temporary model in `/models/encrypt_columns/your_model.rb`.
    #
    class EncryptColumns
      def perform(model, attributes, from, to)
        model = model.constantize if model.is_a?(String)

        # If sidekiq hasn't undergone a restart, its idea of what columns are
        # present may be inaccurate, so ensure this is as fresh as possible
        model.reset_column_information
        model.define_attribute_methods

        attributes = expand_attributes(model, Array(attributes).map(&:to_sym))

        model.transaction do
          # Use SELECT ... FOR UPDATE to prevent the value being changed while
          # we are encrypting it
          relation = model.where(id: from..to).lock

          relation.each do |instance|
            encrypt!(instance, attributes)
          end
        end
      end

      def clear_migrated_values?
        true
      end

      private

      # Build a hash of { attribute => encrypted column name }
      def expand_attributes(klass, attributes)
        expanded = attributes.flat_map do |attribute|
          attr_config = klass.encrypted_attributes[attribute]
          crypt_column_name = attr_config&.fetch(:attribute)

          raise "Couldn't determine encrypted column for #{klass}##{attribute}" if
            crypt_column_name.nil?

          raise "#{klass} source column: #{attribute} is missing" unless
            klass.column_names.include?(attribute.to_s)

          # Running the migration without the destination column being present
          # leads to data loss
          raise "#{klass} destination column: #{crypt_column_name} is missing" unless
            klass.column_names.include?(crypt_column_name.to_s)

          [attribute, crypt_column_name]
        end

        Hash[*expanded]
      end

      # Generate ciphertext for each column and update the database
      def encrypt!(instance, attributes)
        to_clear = attributes
          .map { |plain, crypt| apply_attribute!(instance, plain, crypt) }
          .compact
          .flat_map { |plain| [plain, nil] }

        to_clear = Hash[*to_clear]

        if instance.changed?
          instance.save!

          if clear_migrated_values?
            instance.update_columns(to_clear)
          end
        end
      end

      def apply_attribute!(instance, plain_column, crypt_column)
        plaintext = instance[plain_column]
        ciphertext = instance[crypt_column]

        # No need to do anything if the plaintext is nil, or an encrypted
        # value already exists
        return unless plaintext.present?
        return if ciphertext.present?

        # attr_encrypted will calculate and set the expected value for us
        instance.public_send("#{plain_column}=", plaintext) # rubocop:disable GitlabSecurity/PublicSend

        plain_column
      end
    end
  end
end
