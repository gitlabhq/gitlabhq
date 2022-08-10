# frozen_string_literal: true

module Integrations
  module BaseDataFields
    extend ActiveSupport::Concern

    LEGACY_FOREIGN_KEY_NAME = %w(
      Integrations::IssueTrackerData
    ).freeze

    included do
      # TODO: Once we rename the tables we can't rely on `table_name` anymore.
      # https://gitlab.com/gitlab-org/gitlab/-/issues/331953
      belongs_to :integration, inverse_of: self.table_name.to_sym, foreign_key: foreign_key_name

      validates :integration, presence: true
    end

    class_methods do
      def encryption_options
        {
          key: Settings.attr_encrypted_db_key_base_32,
          encode: true,
          mode: :per_attribute_iv,
          algorithm: 'aes-256-gcm'
        }
      end

      private

      # Older data field models use the `service_id` foreign key for the
      # integration association.
      def foreign_key_name
        return :service_id if self.name.in?(LEGACY_FOREIGN_KEY_NAME)

        :integration_id
      end
    end

    def activated?
      !!integration&.activated?
    end

    def to_database_hash
      as_json(
        only: self.class.column_names
      ).except('id', 'service_id', 'integration_id', 'created_at', 'updated_at')
    end
  end
end
