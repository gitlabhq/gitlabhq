# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Representation
      module DiffNotes
        class DiscussionId
          NOTEABLE_TYPE = 'MergeRequest'
          DISCUSSION_CACHE_REGEX = %r{/(?<repo>[^/]*)/pull/(?<iid>\d+)}i
          DISCUSSION_CACHE_KEY = 'github-importer/discussion-id-map/%{project}/%{noteable_id}/%{original_note_id}'

          def initialize(note)
            @note = note
            @matches = note[:html_url].match(DISCUSSION_CACHE_REGEX)
          end

          def find_or_generate
            (note[:in_reply_to_id].present? && current_discussion_id) || generate_discussion_id
          end

          private

          attr_reader :note, :matches

          def generate_discussion_id
            discussion_id = Discussion.discussion_id(
              Struct
              .new(:noteable_id, :noteable_type)
              .new(matches[:iid].to_i, NOTEABLE_TYPE)
            )
            cache_discussion_id(discussion_id)
          end

          def cache_discussion_id(discussion_id)
            Gitlab::Cache::Import::Caching.write(
              discussion_id_cache_key(note[:id]), discussion_id
            )
          end

          def current_discussion_id
            Gitlab::Cache::Import::Caching.read(
              discussion_id_cache_key(note[:in_reply_to_id])
            )
          end

          def discussion_id_cache_key(id)
            format(DISCUSSION_CACHE_KEY,
              project: matches[:repo],
              noteable_id: matches[:iid].to_i,
              original_note_id: id
            )
          end
        end
      end
    end
  end
end
