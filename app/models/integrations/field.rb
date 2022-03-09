# frozen_string_literal: true

module Integrations
  class Field
    SENSITIVE_NAME = %r/token|key|password|passphrase|secret/.freeze

    ATTRIBUTES = %i[
      section type placeholder required choices value checkbox_label
      title help
      non_empty_password_help
      non_empty_password_title
      api_only
    ].freeze

    attr_reader :name

    def initialize(name:, type: 'text', api_only: false, **attributes)
      @name = name.to_s.freeze

      attributes[:type] = SENSITIVE_NAME.match?(@name) ? 'password' : type
      attributes[:api_only] = api_only
      @attributes = attributes.freeze
    end

    def [](key)
      return name if key == :name

      value = @attributes[key]
      return value.call if value.respond_to?(:call)

      value
    end

    def sensitive?
      @attributes[:type] == 'password'
    end

    ATTRIBUTES.each do |name|
      define_method(name) { self[name] }
    end
  end
end
