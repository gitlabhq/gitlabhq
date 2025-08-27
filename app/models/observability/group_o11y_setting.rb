# frozen_string_literal: true

module Observability
  class GroupO11ySetting < ApplicationRecord
    HUMANIZED_ATTRIBUTES = {
      o11y_service_url: 'O11y service name'
    }.freeze

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

    attr_writer :o11y_service_name

    def self.human_attribute_name(attribute, *options)
      HUMANIZED_ATTRIBUTES[attribute.to_sym] || super
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
  end
end
