# frozen_string_literal: true

module Integrations
  module EnableSslVerification
    extend ActiveSupport::Concern

    prepended do
      field :enable_ssl_verification,
        type: :checkbox,
        title: -> { s_('Integrations|SSL verification') },
        checkbox_label: -> { s_('Integrations|Enable SSL verification') },
        help: -> { s_('Integrations|Clear if using a self-signed certificate.') },
        description: -> { s_('Enable SSL verification. Defaults to `true` (enabled).') }
    end

    def initialize_properties
      super

      self.enable_ssl_verification = true if new_record? && enable_ssl_verification.nil?
    end

    def fields
      super.tap do |fields|
        url_index = fields.index { |field| field[:name].ends_with?('_url') }
        insert_index = url_index || -1

        enable_ssl_verification_index = fields.index { |field| field[:name] == 'enable_ssl_verification' }

        fields.insert(insert_index, fields.delete_at(enable_ssl_verification_index))
      end
    end
  end
end
