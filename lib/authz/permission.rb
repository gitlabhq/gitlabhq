# frozen_string_literal: true

module Authz
  class Permission
    include Authz::Concerns::YamlPermission

    BASE_PATH = 'config/authz/permissions'

    class << self
      def config_path
        Rails.root.join(BASE_PATH, '**/[_a-z]?*.yml')
      end
    end

    # Returns the broader permissions declared via `conditionally_enables:`
    # as an array of symbols, or nil if the field is absent. A bare string
    # in YAML is normalized to a single-element array.
    def conditionally_enables
      value = definition[:conditionally_enables]
      return if value.nil?

      Array(value).map(&:to_sym)
    end
  end
end
