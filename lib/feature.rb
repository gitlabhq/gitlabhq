require 'flipper/adapters/active_record'

class Feature
  # Classes to override flipper table names
  class FlipperFeature < Flipper::Adapters::ActiveRecord::Feature
    # Using `self.table_name` won't work. ActiveRecord bug?
    superclass.table_name = 'features'
  end

  class FlipperGate < Flipper::Adapters::ActiveRecord::Gate
    superclass.table_name = 'feature_gates'
  end

  class << self
    def all
      flipper.features.to_a
    end

    def get(key)
      flipper.feature(key)
    end

    def persisted?(feature)
      # Flipper creates on-memory features when asked for a not-yet-created one.
      # If we want to check if a feature has been actually set, we look for it
      # on the persisted features list.
      all.map(&:name).include?(feature.name)
    end

    private

    def flipper
      @flipper ||= begin
        adapter = Flipper::Adapters::ActiveRecord.new(
          feature_class: FlipperFeature, gate_class: FlipperGate)

        Flipper.new(adapter)
      end
    end
  end
end
