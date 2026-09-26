# frozen_string_literal: true

module Authz
  module RedactionPolicyClassMaps
    STORE_KEY = :redaction_policy_class_maps

    def self.memoize
      previous = Gitlab::SafeRequestStore[STORE_KEY]
      Gitlab::SafeRequestStore[STORE_KEY] = previous || Hash.new { |maps, name| maps[name] = {} }
      yield
    ensure
      Gitlab::SafeRequestStore[STORE_KEY] = previous
    end

    %i[conditions ability_map global_actions delegations].each do |name|
      define_method(name) do
        maps = Gitlab::SafeRequestStore[STORE_KEY]
        return super() unless maps

        maps[name][self] ||= super()
      end
    end
  end
end
