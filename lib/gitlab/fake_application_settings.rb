# This class extends an OpenStruct object by adding predicate methods to mimic
# ActiveRecord access. We rely on the initial values being true or false to
# determine whether to define a predicate method because for a newly-added
# column that has not been migrated yet, there is no way to determine the
# column type without parsing db/schema.rb.
module Gitlab
  class FakeApplicationSettings < OpenStruct
    # Mimic ActiveRecord predicate methods for boolean values
    def self.define_predicate_methods(options)
      options.each do |key, value|
        next if key.to_s.end_with?('?')
        next unless [true, false].include?(value)

        define_method "#{key}?" do
          actual_key = key.to_s.chomp('?')
          self[actual_key]
        end
      end
    end

    def initialize(options = {})
      super

      FakeApplicationSettings.define_predicate_methods(options)
    end

    def key_restriction_for(type)
      0
    end

    def allowed_key_types
      ApplicationSetting::SUPPORTED_KEY_TYPES
    end

    def pick_repository_storage
      repository_storages.sample
    end
  end
end
