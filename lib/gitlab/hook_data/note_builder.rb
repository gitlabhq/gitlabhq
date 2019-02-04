# frozen_string_literal: true

module Gitlab
  module HookData
    class NoteBuilder < BaseBuilder
      SAFE_HOOK_ATTRIBUTES = %i[
        attachment
        author_id
        change_position
        commit_id
        created_at
        discussion_id
        id
        line_code
        note
        noteable_id
        noteable_type
        original_position
        position
        project_id
        resolved_at
        resolved_by_id
        resolved_by_push
        st_diff
        system
        type
        updated_at
        updated_by_id
      ].freeze

      alias_method :note, :object

      def build
        note
          .attributes
          .with_indifferent_access
          .slice(*SAFE_HOOK_ATTRIBUTES)
          .merge(
            description: absolute_image_urls(note.note),
            url: Gitlab::UrlBuilder.build(note)
          )
      end
    end
  end
end
