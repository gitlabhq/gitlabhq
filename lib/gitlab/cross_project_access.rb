# frozen_string_literal: true

module Gitlab
  class CrossProjectAccess
    class << self
      delegate :add_check, :find_check, :checks,
        to: :instance
    end

    def self.instance
      @instance ||= new
    end

    attr_reader :checks

    def initialize
      @checks = {}
    end

    def add_check(
      klass,
      actions: {},
      positive_condition: nil,
      negative_condition: nil,
      skip: false)

      new_check = CheckInfo.new(actions,
        positive_condition,
        negative_condition,
        skip
      )

      @checks[klass] ||= Gitlab::CrossProjectAccess::CheckCollection.new
      @checks[klass].add_check(new_check)
      recalculate_checks_for_class(klass)

      @checks[klass]
    end

    def find_check(object)
      @cached_checks ||= Hash.new do |cache, new_class|
        parent_classes = @checks.keys.select { |existing_class| new_class <= existing_class }
        closest_class = closest_parent(parent_classes, new_class)
        cache[new_class] = @checks[closest_class]
      end

      @cached_checks[object.class]
    end

    private

    def recalculate_checks_for_class(klass)
      new_collection = @checks[klass]

      @checks.each do |existing_class, existing_check_collection|
        if existing_class < klass
          existing_check_collection.add_collection(new_collection)
        elsif klass < existing_class
          new_collection.add_collection(existing_check_collection)
        end
      end
    end

    def closest_parent(classes, subject)
      relevant_ancestors = subject.ancestors & classes
      relevant_ancestors.first
    end
  end
end
