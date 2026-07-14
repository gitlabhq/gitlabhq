# frozen_string_literal: true

module ExportCsv # rubocop:disable Gitlab/BoundedContexts -- pre-existing namespace shared with the other CSV exporters
  class KeysetCollection
    BATCH_SIZE = 1000

    def initialize(relation, associations_to_preload: [], on_batch_loaded: nil)
      @relation = relation
      @associations_to_preload = associations_to_preload
      @on_batch_loaded = on_batch_loaded
    end

    def count
      relation.count
    end

    def each(&block)
      iterator.each_batch(of: BATCH_SIZE) do |batch|
        records = batch.to_a
        preload_associations(records)
        @on_batch_loaded&.call(records)
        records.each(&block)
      end
    end

    private

    attr_reader :relation, :associations_to_preload

    def iterator
      scope = relation.reorder(created_at: :asc, id: :asc) # rubocop:disable CodeReuse/ActiveRecord -- keyset scope
      Gitlab::Pagination::Keyset::Iterator.new(scope: scope)
    end

    def preload_associations(records)
      return if associations_to_preload.blank?

      ActiveRecord::Associations::Preloader.new(records: records, associations: associations_to_preload).call
    end
  end
end
