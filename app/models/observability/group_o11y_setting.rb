# frozen_string_literal: true

module Observability
  class GroupO11ySetting < ApplicationRecord
    HUMANIZED_ATTRIBUTES = {
      o11y_service_url: 'O11y service name'
    }.freeze
    SETUP_WINDOW = 5.minutes

    belongs_to :group, inverse_of: :observability_group_o11y_setting

    validates :o11y_service_url, length: { maximum: 255 }, addressable_url: { message: 'is invalid' }
    validate :validate_email_format
    encrypts :o11y_service_password, :o11y_service_post_message_encryption_key
    validates :o11y_service_password, length: { maximum: 510 },
      json_schema: {
        filename: 'o11y_service_password',
        size_limit: 64.kilobytes,
        message: 'is invalid'
      }
    validates :o11y_service_post_message_encryption_key, length: { maximum: 510 },
      json_schema: {
        filename: 'o11y_service_post_message_encryption_key',
        size_limit: 64.kilobytes,
        message: 'is invalid'
      }

    scope :with_group, -> { includes(:group) }
    scope :search_by_group_id, ->(group_id) { where(group_id: group_id) }

    attr_writer :o11y_service_name

    def self.find_by_group_id(group_id)
      find_by(group_id: group_id)
    end

    def self.human_attribute_name(attribute, *options)
      HUMANIZED_ATTRIBUTES[attribute.to_sym] || super
    end

    def self.observability_setting_for(resource)
      return unless resource

      group = resource.is_a?(Project) ? resource.group : resource
      return unless group.is_a?(Group)

      ancestor_ids = group.traversal_ids.reverse
      return if ancestor_ids.empty?

      # Find the first setting matching any ancestor, maintaining hierarchy order
      # by using array_position to preserve the order from ancestor_ids
      group_id_attribute = arel_table[:group_id]
      array_sql = "array_position(ARRAY[#{ancestor_ids.join(',')}]::bigint[], " \
        "#{group_id_attribute.relation.name}.#{group_id_attribute.name})"
      where(group_id: ancestor_ids)
        .order(Arel.sql(array_sql))
        .first
    end

    def o11y_service_name
      @o11y_service_name || name_from_url || name_from_group
    end

    def name_from_url
      return unless o11y_service_url

      o11y_service_url.to_s.gsub(%r{https://|\.gitlab-o11y\.com}, '')
    end

    def name_from_group
      group&.full_path&.to_s&.tr('/', '-')
    end

    def validate_email_format
      if o11y_service_user_email.blank?
        errors.add(:o11y_service_user_email, I18n.t(:invalid, scope: 'activerecord.errors.messages'))
        return
      end

      return if ValidateEmail.valid?(o11y_service_user_email)

      errors.add(:o11y_service_user_email, I18n.t(:invalid, scope: 'valid_email.validations.email'))
    end

    def provisioning?
      within_provisioning_window? || new_record?
    end

    def otel_http_endpoint
      "http://#{otel_address}:4318"
    end

    def otel_grpc_endpoint
      "http://#{otel_address}:4317"
    end

    def otel_address
      "#{o11y_service_name}.otel.gitlab-o11y.com"
    end

    private

    def within_provisioning_window?
      return false unless persisted?

      Time.current.before?(created_at + SETUP_WINDOW)
    end
  end
end
