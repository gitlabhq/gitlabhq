module Gitlab
  module DataBuilder
    module Note
      extend self

      # Produce a hash of post-receive data
      #
      # For all notes:
      #
      # data = {
      #   object_kind: "note",
      #   event_type: "confidential_note",
      #   user: {
      #     name: String,
      #     username: String,
      #     avatar_url: String
      #   }
      #   project_id: Integer,
      #   repository: {
      #     name: String,
      #     url: String,
      #     description: String,
      #     homepage: String,
      #   }
      #  object_attributes: {
      #    <hook data for note>
      #  }
      #  <note-specific data>: {
      # }
      # note-specific data is a hash with one of the following keys and contains
      # the hook data for that type.
      #  - commit
      #  - issue
      #  - merge_request
      #  - snippet
      #
      def build(note, user)
        project = note.project
        data = build_base_data(project, user, note)

        if note.for_commit?
          data[:commit] = build_data_for_commit(project, user, note)
        elsif note.for_issue?
          data[:issue] = note.noteable.hook_attrs
        elsif note.for_merge_request?
          data[:merge_request] = note.noteable.hook_attrs
        elsif note.for_snippet?
          data[:snippet] = note.noteable.hook_attrs
        end

        data
      end

      def build_base_data(project, user, note)
        event_type = note.confidential? ? 'confidential_note' : 'note'

        base_data = {
          object_kind: "note",
          event_type: event_type,
          user: user.hook_attrs,
          project_id: project.id,
          project: project.hook_attrs,
          object_attributes: note.hook_attrs,
          # DEPRECATED
          repository: project.hook_attrs.slice(:name, :url, :description, :homepage)
        }

        base_data[:object_attributes][:url] = Gitlab::UrlBuilder.build(note)
        base_data
      end

      def build_data_for_commit(project, user, note)
        # commit_id is the SHA hash
        commit = project.commit(note.commit_id)
        commit.hook_attrs
      end
    end
  end
end
