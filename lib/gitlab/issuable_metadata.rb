# frozen_string_literal: true

module Gitlab
  class IssuableMetadata
    include Gitlab::Utils::StrongMemoize

    # data structure to store issuable meta data like
    # upvotes, downvotes, notes and closing merge requests counts for issues and merge requests
    # this avoiding n+1 queries when loading issuable collections on frontend
    IssuableMeta = Struct.new(
      :upvotes,
      :downvotes,
      :user_notes_count,
      :merge_requests_count,
      :blocking_issues_count # EE-ONLY
    )

    attr_reader :current_user, :issuable_collection

    def initialize(current_user, issuable_collection)
      @current_user = current_user
      @issuable_collection = issuable_collection

      validate_collection!
    end

    def data
      return {} if issuable_ids.empty?

      issuable_ids.each_with_object({}) do |id, issuable_meta|
        issuable_meta[id] = metadata_for_issuable(id)
      end
    end

    private

    def metadata_for_issuable(id)
      downvotes = group_issuable_votes_count.find { |votes| votes.awardable_id == id && votes.downvote? }
      upvotes = group_issuable_votes_count.find { |votes| votes.awardable_id == id && votes.upvote? }
      notes = grouped_issuable_notes_count.find { |notes| notes.noteable_id == id }
      merge_requests = grouped_issuable_merge_requests_count.find { |mr| mr.first == id }

      IssuableMeta.new(
        upvotes.try(:count).to_i,
        downvotes.try(:count).to_i,
        notes.try(:count).to_i,
        merge_requests.try(:last).to_i
      )
    end

    def validate_collection!
      # ActiveRecord uses Object#extend for null relations.
      if !(issuable_collection.singleton_class < ActiveRecord::NullRelation) &&
          issuable_collection.respond_to?(:limit_value) &&
          issuable_collection.limit_value.nil?

        raise 'Collection must have a limit applied for preloading meta-data'
      end
    end

    def issuable_ids
      strong_memoize(:issuable_ids) do
        # map has to be used here since using pluck or select will
        # throw an error when ordering issuables by priority which inserts
        # a new order into the collection.
        # We cannot use reorder to not mess up the paginated collection.
        issuable_collection.map(&:id)
      end
    end

    def collection_type
      # Supports relations or paginated arrays
      issuable_collection.try(:model)&.name ||
        issuable_collection.first&.model_name.to_s
    end

    def group_issuable_votes_count
      strong_memoize(:group_issuable_votes_count) do
        AwardEmoji.votes_for_collection(issuable_ids, collection_type)
      end
    end

    def grouped_issuable_notes_count
      strong_memoize(:grouped_issuable_notes_count) do
        ::Note.count_for_collection(issuable_ids, collection_type)
      end
    end

    def grouped_issuable_merge_requests_count
      strong_memoize(:grouped_issuable_merge_requests_count) do
        if collection_type == 'Issue'
          ::MergeRequestsClosingIssues.count_for_collection(issuable_ids, current_user)
        else
          []
        end
      end
    end
  end
end

Gitlab::IssuableMetadata.prepend_mod_with('Gitlab::IssuableMetadata')
