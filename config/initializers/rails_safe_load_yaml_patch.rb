# frozen_string_literal: true
# rubocop:disable Database/MultipleDatabases

raise 'This patch should be dropped after upgrading Rails v6.1.6.1' if ActiveRecord::VERSION::STRING != "6.1.6.1"

module ActiveRecord
  module Coders # :nodoc:
    class YAMLColumn # :nodoc:
      private

      def yaml_load(payload)
        return legacy_yaml_load(payload) if ActiveRecord::Base.use_yaml_unsafe_load

        YAML.safe_load(payload, permitted_classes: ActiveRecord::Base.yaml_column_permitted_classes, aliases: true)
      rescue Psych::DisallowedClass => e
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)

        legacy_yaml_load(payload)
      end

      def legacy_yaml_load(payload)
        if YAML.respond_to?(:unsafe_load)
          YAML.unsafe_load(payload)
        else
          YAML.load(payload) # rubocop:disable Security/YAMLLoad
        end
      end
    end
  end
end

# rubocop:enable Database/MultipleDatabases
