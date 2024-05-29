# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Representation
      class Note
        include Representable

        expose_attribute :noteable_id, :noteable_type, :author, :note,
          :created_at, :updated_at, :note_id

        NOTEABLE_TYPE_REGEX = %r{/(?<type>(pull|issues))/(?<iid>\d+)}i

        # Builds a note from a GitHub API response.
        #
        # note - An instance of `Hash` containing the note details.
        def self.from_api_response(note, additional_data = {})
          matches = note[:html_url].match(NOTEABLE_TYPE_REGEX)

          if !matches || !matches[:type]
            raise(
              ArgumentError,
              "The note URL #{note[:html_url].inspect} is not supported"
            )
          end

          noteable_type =
            if matches[:type] == 'pull'
              'MergeRequest'
            else
              'Issue'
            end

          user = Representation::User.from_api_response(note[:user]) if note[:user]
          hash = {
            noteable_type: noteable_type,
            noteable_id: matches[:iid].to_i,
            author: user,
            note: note[:body],
            created_at: note[:created_at],
            updated_at: note[:updated_at],
            note_id: note[:id]
          }

          new(hash)
        end

        # Builds a new note using a Hash that was built from a JSON payload.
        def self.from_json_hash(raw_hash)
          hash = Representation.symbolize_hash(raw_hash)

          hash[:author] &&= Representation::User.from_json_hash(hash[:author])

          new(hash)
        end

        # attributes - A Hash containing the raw note details. The keys of this
        #              Hash must be Symbols.
        def initialize(attributes)
          @attributes = attributes
        end

        def discussion_id
          Discussion.discussion_id(
            Struct
            .new(:noteable_id, :noteable_type)
            .new(noteable_id, noteable_type)
          )
        end

        alias_method :issuable_type, :noteable_type

        def github_identifiers
          {
            note_id: note_id,
            noteable_iid: noteable_id,
            noteable_type: noteable_type
          }
        end
      end
    end
  end
end
