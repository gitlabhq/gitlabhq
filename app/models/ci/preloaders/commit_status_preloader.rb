# frozen_string_literal: true

module Ci
  module Preloaders
    class CommitStatusPreloader
      CLASSES = [::Ci::Build, ::Ci::Bridge, ::GenericCommitStatus].freeze

      def initialize(statuses)
        @statuses = statuses
      end

      # Each association loads once for all statuses whose class defines it, since
      # Rails raises when a record's class lacks one. A row shared between classes
      # (the project) is then one instance: Rails batches loaders that build the
      # same query even where a subclass redeclares the association.
      def execute(relations, scope: nil)
        relations = normalize(relations)
        validate!(relations)

        relations.group_by { |entry| owners(entry) }.each do |owners, associations|
          preload(objects(owners), associations, scope)
        end
      end

      private

      def records
        @records ||= @statuses.to_a
      end

      def objects(klasses)
        records.select { |job| klasses.any? { |klass| job.is_a?(klass) } }
      end

      def preload(records, associations, scope)
        return if records.empty? || associations.empty?

        ActiveRecord::Associations::Preloader.new(records: records, associations: associations, scope: scope).call
      end

      # One entry per association: `{ a: x, b: y }` becomes `[{ a: x }, { b: y }]`.
      def normalize(relations)
        Array.wrap(relations).flatten.flat_map do |entry|
          if entry.is_a?(Hash)
            entry.map { |name, nested| { name.to_sym => nested } }
          elsif entry.respond_to?(:to_sym)
            [entry.to_sym]
          else
            raise ArgumentError, "Invalid relation: #{entry.inspect}"
          end
        end
      end

      # A name no class defines is a typo in a caller's list. Raise in development
      # and test so it is caught there; in production skip it, as this preloader
      # did before, so a typo costs an N+1 rather than the request.
      def validate!(relations)
        unknown = relations.select { |entry| owners(entry).empty? }
        return if unknown.empty?

        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
          ArgumentError.new("Unknown associations for CommitStatus preload: #{unknown.inspect}")
        )
      end

      def association_name(entry)
        entry.is_a?(Hash) ? entry.each_key.first : entry
      end

      def owners(entry)
        CLASSES.select { |klass| klass.reflect_on_association(association_name(entry)) }
      end
    end
  end
end
