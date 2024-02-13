# frozen_string_literal: true

module Preloaders
  class CommitStatusPreloader
    CLASSES = [::Ci::Build, ::Ci::Bridge, ::GenericCommitStatus].freeze

    def initialize(statuses)
      @statuses = statuses
    end

    def execute(relations)
      CLASSES.each do |klass|
        ActiveRecord::Associations::Preloader.new(
          records: objects(klass),
          associations: associations(klass, relations)
        ).call
      end
    end

    private

    def objects(klass)
      @statuses.select { |job| job.is_a?(klass) }
    end

    def associations(klass, relations)
      klass_reflections = klass.reflections.keys.map(&:to_sym).to_set

      result = []
      relations.each do |entry|
        if entry.respond_to?(:to_sym)
          result << entry.to_sym if klass_reflections.include?(entry.to_sym)
        elsif entry.is_a?(Hash)
          entry = entry.select do |key, _value|
            klass_reflections.include?(key.to_sym)
          end

          result << entry if entry.present?
        else
          raise ArgumentError, "Invalid relation: #{entry.inspect}"
        end
      end

      result
    end
  end
end
