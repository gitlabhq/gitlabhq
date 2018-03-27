module Gitlab
  module IssuableMetadata
    def issuable_meta_data(issuable_collection, collection_type)
      # ActiveRecord uses Object#extend for null relations.
      if !(issuable_collection.singleton_class < ActiveRecord::NullRelation) &&
          issuable_collection.respond_to?(:limit_value) &&
          issuable_collection.limit_value.nil?

        raise 'Collection must have a limit applied for preloading meta-data'
      end

      # map has to be used here since using pluck or select will
      # throw an error when ordering issuables by priority which inserts
      # a new order into the collection.
      # We cannot use reorder to not mess up the paginated collection.
      issuable_ids = issuable_collection.map(&:id)

      return {} if issuable_ids.empty?

      issuable_note_count = ::Note.count_for_collection(issuable_ids, collection_type)
      issuable_votes_count = ::AwardEmoji.votes_for_collection(issuable_ids, collection_type)
      issuable_merge_requests_count =
        if collection_type == 'Issue'
          ::MergeRequestsClosingIssues.count_for_collection(issuable_ids)
        else
          []
        end

      issuable_ids.each_with_object({}) do |id, issuable_meta|
        downvotes = issuable_votes_count.find { |votes| votes.awardable_id == id && votes.downvote? }
        upvotes = issuable_votes_count.find { |votes| votes.awardable_id == id && votes.upvote? }
        notes = issuable_note_count.find { |notes| notes.noteable_id == id }
        merge_requests = issuable_merge_requests_count.find { |mr| mr.first == id }

        issuable_meta[id] = ::Issuable::IssuableMeta.new(
          upvotes.try(:count).to_i,
          downvotes.try(:count).to_i,
          notes.try(:count).to_i,
          merge_requests.try(:last).to_i
        )
      end
    end
  end
end
