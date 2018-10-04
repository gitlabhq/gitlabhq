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
        next unless key_with_nil = values.key(nil)

        # E.g. for enum_with_nil failure_reason: { unknown_failure: nil }
        # this overrides auto-generated method `unknown_failure?`
        define_method("#{key_with_nil}?") do
          Gitlab.rails5? ? self[name].nil? : super()
        end

        # E.g. for enum_with_nil failure_reason: { unknown_failure: nil }
        # this overrides auto-generated method `failure_reason`
        define_method(name) do
          orig = super()

          return orig unless Gitlab.rails5?
          return orig unless orig.nil?

          self.class.public_send(name.to_s.pluralize).key(nil) # rubocop:disable GitlabSecurity/PublicSend
        end
      end
    end
  end
end
