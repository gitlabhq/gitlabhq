# frozen_string_literal: true

module Integrations
  module BaseDataFields
    extend ActiveSupport::Concern

    included do
      include Gitlab::EncryptedAttribute

      belongs_to :integration, inverse_of: self.table_name.to_sym, foreign_key: :integration_id, optional: true
      belongs_to :project, inverse_of: self.table_name.to_sym, foreign_key: :project_id, optional: true
      belongs_to :group, inverse_of: self.table_name.to_sym, foreign_key: :group_id, optional: true
      belongs_to :organization, inverse_of: self.table_name.to_sym, foreign_key: :organization_id, optional: true

      before_validation :set_sharding_key

      validates :integration, presence: true
      validate :validate_sharding_key
    end

    class_methods do
      def encryption_options
        {
          key: :db_key_base_32,
          encode: true,
          mode: :per_attribute_iv,
          algorithm: 'aes-256-gcm'
        }
      end
    end

    def activated?
      !!integration&.activated?
    end

    def to_database_hash
      as_json(
        only: self.class.column_names
      ).except(
        'id',
        'service_id',
        'integration_id',
        'created_at',
        'updated_at',
        'group_id',
        'project_id',
        'organization_id'
      )
    end

    private

    def set_sharding_key
      return if project_id || group_id || organization_id || integration.nil?

      self.project_id = integration.project_id if integration.project_id
      self.group_id = integration.group_id if integration.group_id
      self.organization_id = integration.organization_id if integration.organization_id
    end

    def validate_sharding_key
      return if project_id.present? || group_id.present? || organization_id.present?

      errors.add(:base, :blank, message: 'one of project_id, group_id or organization_id must be present')
    end
  end
end
