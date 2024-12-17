# frozen_string_literal: true

module Integrations
  class FieldEntity < Grape::Entity
    include RequestAwareEntity
    include Gitlab::Utils::StrongMemoize

    expose :section, :name, :placeholder, :required, :choices, :checkbox_label, :label_description

    expose :title do |field|
      non_empty_password?(field) ? field[:non_empty_password_title] : field[:title]
    end

    expose :type do |field|
      field[:type].to_s
    end

    expose :help do |field|
      non_empty_password?(field) ? field[:non_empty_password_help] : field[:help]
    end

    expose :value do |field|
      value = value_for(field)

      if non_empty_password?(field)
        'true'
      elsif field[:type] == :checkbox
        ActiveRecord::Type::Boolean.new.deserialize(value).to_s
      elsif field[:name] == 'webhook' && integration.chat?
        Base::ChatNotification::SECRET_MASK if value.present?
      else
        value
      end
    end

    private

    def integration
      request.integration
    end

    def value_for(field)
      strong_memoize(:value_for) do
        # field[:name] is not user input and so can assume is safe
        integration.public_send(field[:name]) # rubocop:disable GitlabSecurity/PublicSend
      end
    end

    def non_empty_password?(field)
      strong_memoize(:non_empty_password) do
        field[:type] == :password && value_for(field).present?
      end
    end
  end
end
