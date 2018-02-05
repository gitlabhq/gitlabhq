# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Representation
      class DiffNote
        include ToHash
        include ExposeAttribute

        attr_reader :attributes

        expose_attribute :noteable_type, :noteable_id, :commit_id, :file_path,
                         :diff_hunk, :author, :note, :created_at, :updated_at,
                         :github_id

        NOTEABLE_ID_REGEX = %r{/pull/(?<iid>\d+)}i

        # Builds a diff note from a GitHub API response.
        #
        # note - An instance of `Sawyer::Resource` containing the note details.
        def self.from_api_response(note)
          matches = note.html_url.match(NOTEABLE_ID_REGEX)

          unless matches
            raise(
              ArgumentError,
              "The note URL #{note.html_url.inspect} is not supported"
            )
          end

          user = Representation::User.from_api_response(note.user) if note.user
          hash = {
            noteable_type: 'MergeRequest',
            noteable_id: matches[:iid].to_i,
            file_path: note.path,
            commit_id: note.commit_id,
            diff_hunk: note.diff_hunk,
            author: user,
            note: note.body,
            created_at: note.created_at,
            updated_at: note.updated_at,
            github_id: note.id
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

        def line_code
          diff_line = Gitlab::Diff::Parser.new.parse(diff_hunk.lines).to_a.last

          Gitlab::Git
            .diff_line_code(file_path, diff_line.new_pos, diff_line.old_pos)
        end

        # Returns a Hash that can be used to populate `notes.st_diff`, removing
        # the need for requesting Git data for every diff note.
        def diff_hash
          {
            diff: diff_hunk,
            new_path: file_path,
            old_path: file_path,

            # These fields are not displayed for LegacyDiffNote notes, so it
            # doesn't really matter what we set them to.
            a_mode: '100644',
            b_mode: '100644',
            new_file: false
          }
        end
      end
    end
  end
end
