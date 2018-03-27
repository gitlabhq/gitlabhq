# Remove this file when upgraded to rails 5.0.
unless Gitlab.rails5?
  module ActiveRecord
    module Batches
      # Differences from upstream: enumerator support was removed, and custom
      # order/limit clauses are ignored without a warning.
      def in_batches(of: 1000, start: nil, finish: nil, load: false)
        raise "Must provide a block" unless block_given?

        relation = self.reorder(batch_order).limit(of)
        relation = relation.where(arel_table[primary_key].gteq(start)) if start
        relation = relation.where(arel_table[primary_key].lteq(finish)) if finish
        batch_relation = relation

        loop do
          if load
            records = batch_relation.records
            ids = records.map(&:id)
            yielded_relation = self.where(primary_key => ids)
            yielded_relation.load_records(records)
          else
            ids = batch_relation.pluck(primary_key)
            yielded_relation = self.where(primary_key => ids)
          end

          break if ids.empty?

          primary_key_offset = ids.last
          raise ArgumentError.new("Primary key not included in the custom select clause") unless primary_key_offset

          yield yielded_relation

          break if ids.length < of

          batch_relation = relation.where(arel_table[primary_key].gt(primary_key_offset))
        end
      end
    end
  end
end
