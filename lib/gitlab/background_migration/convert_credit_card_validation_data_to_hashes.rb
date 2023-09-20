# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Converts a credit card's expiration_date, last_digits, network & holder_name
    # to hash and store values in new columns
    class ConvertCreditCardValidationDataToHashes < BatchedMigrationJob
      operation_name :convert_credit_card_data
      feature_category :user_profile

      class CreditCardValidation < ApplicationRecord # rubocop:disable Style/Documentation
        self.table_name = 'user_credit_card_validations'
      end

      def perform
        each_sub_batch do |sub_batch|
          credit_cards = CreditCardValidation.where(user_id: sub_batch)

          credit_card_hashes = credit_cards.map do |c|
            {
              user_id: c.user_id,
              credit_card_validated_at: c.credit_card_validated_at,
              last_digits_hash: hashed_value(c.last_digits),
              holder_name_hash: hashed_value(c.holder_name&.downcase),
              network_hash: hashed_value(c.network&.downcase),
              expiration_date_hash: hashed_value(c.expiration_date&.to_s)
            }
          end

          CreditCardValidation.upsert_all(credit_card_hashes)
        end
      end

      def hashed_value(value)
        Gitlab::CryptoHelper.sha256(value) if value.present?
      end
    end
  end
end
