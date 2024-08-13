# frozen_string_literal: true

module Gitlab
  module NoteableMetadata
    def noteable_meta_data(noteable_collection, collection_type)
      # ActiveRecord uses Object#extend for null relations.
      if !(noteable_collection.is_a?(ActiveRecord::Relation) && noteable_collection.null_relation?) &&
          noteable_collection.respond_to?(:limit_value) &&
          noteable_collection.limit_value.nil?

        raise 'Collection must have a limit applied for preloading meta-data'
      end

      # map has to be used here since using pluck or select will
      # throw an error when ordering noteables which inserts
      # a new order into the collection.
      # We cannot use reorder to not mess up the paginated collection.
      noteable_ids = noteable_collection.map(&:id)

      return {} if noteable_ids.empty?

      noteable_notes_count = ::Note.count_for_collection(noteable_ids, collection_type)

      noteable_ids.each_with_object({}) do |id, noteable_meta|
        notes = noteable_notes_count.find { |notes| notes.noteable_id == id }

        noteable_meta[id] = ::Noteable::NoteableMeta.new(
          notes.try(:count).to_i
        )
      end
    end
  end
end
