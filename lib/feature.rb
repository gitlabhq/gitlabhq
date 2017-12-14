class Feature
  # Classes to override flipper table names
  class FlipperFeature < Flipper::Adapters::ActiveRecord::Feature
    # Using `self.table_name` won't work. ActiveRecord bug?
    superclass.table_name = 'features'

    def self.feature_names
      pluck(:key)
    end
  end

  class FlipperGate < Flipper::Adapters::ActiveRecord::Gate
    superclass.table_name = 'feature_gates'
  end

  class << self
    delegate :group, to: :flipper

    def all
      flipper.features.to_a
    end

    def get(key)
      flipper.feature(key)
    end

    def persisted_names
      if RequestStore.active?
        RequestStore[:flipper_persisted_names] ||= FlipperFeature.feature_names
      else
        FlipperFeature.feature_names
      end
    end

    def persisted?(feature)
      # Flipper creates on-memory features when asked for a not-yet-created one.
      # If we want to check if a feature has been actually set, we look for it
      # on the persisted features list.
      persisted_names.include?(feature.name)
    end

    def enabled?(key, thing = nil)
      get(key).enabled?(thing)
    end

    def enable(key, thing = true)
      get(key).enable(thing)
    end

    def disable(key, thing = false)
      get(key).disable(thing)
    end

    def enable_group(key, group)
      get(key).enable_group(group)
    end

    def disable_group(key, group)
      get(key).disable_group(group)
    end

    def flipper
      @flipper ||= Flipper.instance
    end

    # This method is called from config/initializers/flipper.rb and can be used
    # to register Flipper groups.
    # See https://docs.gitlab.com/ee/development/feature_flags.html#feature-groups
    def register_feature_groups
    end
  end
end
