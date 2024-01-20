# frozen_string_literal: true

# Fakes ActiveRecord attribute storage by adding predicate methods to mimic
# ActiveRecord access. We rely on the initial values being true or false to
# determine whether to define a predicate method because for a newly-added
# column that has not been migrated yet, there is no way to determine the
# column type without parsing db/structure.sql.
module Gitlab
  class FakeApplicationSettings
    prepend ApplicationSettingImplementation

    def self.define_properties(settings)
      settings.each do |key, value|
        define_method key do
          read_attribute(key)
        end

        if [true, false].include?(value)
          define_method "#{key}?" do
            read_attribute(key)
          end
        end

        define_method "#{key}=" do |v|
          @table[key.to_sym] = v
        end
      end
    end

    def initialize(settings = {})
      @table = settings.dup

      FakeApplicationSettings.define_properties(settings)
    end

    def read_attribute(key)
      @table[key.to_sym]
    end

    def has_attribute?(key)
      @table.key?(key.to_sym)
    end

    # Mimic behavior of OpenStruct, which absorbs any calls into undefined
    # properties to return `nil`.
    def method_missing(*)
      nil
    end

    def respond_to_missing?(*)
      true
    end
  end
end

Gitlab::FakeApplicationSettings.prepend_mod_with('Gitlab::FakeApplicationSettings')
