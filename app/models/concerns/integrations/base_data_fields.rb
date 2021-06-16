# frozen_string_literal: true

module Integrations
  module BaseDataFields
    extend ActiveSupport::Concern

    included do
      # TODO: Once we rename the tables we can't rely on `table_name` anymore.
      # https://gitlab.com/gitlab-org/gitlab/-/issues/331953
      belongs_to :integration, inverse_of: self.table_name.to_sym, foreign_key: :service_id

      delegate :activated?, to: :integration, allow_nil: true

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
    end
  end
end
