# frozen_string_literal: true

module Gitlab
  module Patch
    module ActionDispatchJourneyFormatter
      def self.prepended(mod)
        mod.alias_method(:old_missing_keys, :missing_keys)
        mod.remove_method(:missing_keys)
      end

      private

      def missing_keys(route, parts)
        missing_keys = nil
        tests = route.path.requirements_for_missing_keys_check
        route.required_parts.each do |key|
          case tests[key]
          when nil
            unless parts[key]
              missing_keys ||= []
              missing_keys << key
            end
          else
            unless tests[key].match?(parts[key])
              missing_keys ||= []
              missing_keys << key
            end
          end
        end
        missing_keys
      end
    end
  end
end
