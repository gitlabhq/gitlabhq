# frozen_string_literal: true

module EnumWithNil
  extend ActiveSupport::Concern

  included do
    def self.enum_with_nil(definitions)
      # use original `enum` to auto-define all methods
      enum(definitions)

      # override auto-defined methods only for the
      # key which uses nil value
      definitions.each do |name, values|
        # E.g. for enum_with_nil failure_reason: { unknown_failure: nil }
        # this overrides auto-generated method `failure_reason`
        define_method(name) do
          orig = super()

          return orig unless orig.nil?

          self.class.public_send(name.to_s.pluralize).key(nil) # rubocop:disable GitlabSecurity/PublicSend
        end
      end
    end
  end
end
