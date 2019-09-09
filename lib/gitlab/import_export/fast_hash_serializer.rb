# frozen_string_literal: true

# ActiveModel::Serialization (https://github.com/rails/rails/blob/v5.0.7/activemodel/lib/active_model/serialization.rb#L184)
# is simple in that it recursively calls `as_json` on each object to
# serialize everything. However, for a model like a Project, this can
# generate a query for every single association, which can add up to tens
# of thousands of queries and lead to memory bloat.
#
# To improve this, we can do several things:

# 1. Use the option tree in http://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html
#    to generate the necessary preload clauses.
#
# 2. We observe that a single project has many issues, merge requests,
#    etc. Instead of serializing everything at once, which could lead to
#    database timeouts and high memory usage, we take each top-level
#    association and serialize the data in batches.
#
#  For example, we serialize the first 100 issues and preload all of
#  their associated events, notes, etc. before moving onto the next
#  batch. When we're done, we serialize merge requests in the same way.
#  We repeat this pattern for the remaining associations specified in
#  import_export.yml.
module Gitlab
  module ImportExport
    class FastHashSerializer
      attr_reader :subject, :tree

      BATCH_SIZE = 100

      def initialize(subject, tree, batch_size: BATCH_SIZE)
        @subject = subject
        @batch_size = batch_size
        @tree = tree
      end

      # Serializes the subject into a Hash for the given option tree
      # (e.g. Project#as_json)
      def execute
        simple_serialize.merge(serialize_includes)
      end

      private

      def simple_serialize
        subject.as_json(
          tree.merge(include: nil, preloads: nil))
      end

      def serialize_includes
        return {} unless includes

        includes
          .map(&method(:serialize_include_definition))
          .compact
          .to_h
      end

      # definition:
      # { labels: { includes: ... } }
      def serialize_include_definition(definition)
        raise ArgumentError, 'definition needs to be Hash' unless definition.is_a?(Hash)
        raise ArgumentError, 'definition needs to have exactly one Hash element' unless definition.one?

        key = definition.first.first
        options = definition.first.second

        record = subject.public_send(key) # rubocop: disable GitlabSecurity/PublicSend
        return unless record

        serialized_record = serialize_record(key, record, options)
        return unless serialized_record

        # `#as_json` always returns keys as `strings`
        [key.to_s, serialized_record]
      end

      def serialize_record(key, record, options)
        unless record.respond_to?(:as_json)
          raise "Invalid type of #{key} is #{record.class}"
        end

        # no has-many relation
        unless record.is_a?(ActiveRecord::Relation)
          return record.as_json(options)
        end

        # has-many relation
        data = []

        record.in_batches(of: @batch_size) do |batch| # rubocop:disable Cop/InBatches
          batch = batch.preload(preloads[key]) if preloads&.key?(key)
          data += batch.as_json(options)
        end

        data
      end

      def includes
        tree[:include]
      end

      def preloads
        tree[:preload]
      end
    end
  end
end
