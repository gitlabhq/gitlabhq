# frozen_string_literal: true

module Issuable
  module Clone
    class ContentRewriter < ::Issuable::Clone::BaseService
      def initialize(current_user, original_entity, new_entity)
        @current_user = current_user
        @original_entity = original_entity
        @new_entity = new_entity
        @project = original_entity.project
      end

      def execute
        rewrite_description
        rewrite_award_emoji(original_entity, new_entity)
        rewrite_notes
      end

      private

      def rewrite_description
        new_entity.update(description: rewrite_content(original_entity.description))
      end

      def rewrite_notes
        new_discussion_ids = {}
        original_entity.notes_with_associations.find_each do |note|
          new_note = note.dup
          new_discussion_ids[note.discussion_id] ||= Discussion.discussion_id(new_note)
          new_params = {
            project: new_entity.project,
            noteable: new_entity,
            discussion_id: new_discussion_ids[note.discussion_id],
            note: rewrite_content(new_note.note),
            note_html: nil,
            created_at: note.created_at,
            updated_at: note.updated_at
          }

          if note.system_note_metadata
            new_params[:system_note_metadata] = note.system_note_metadata.dup
          end

          new_note.update(new_params)

          rewrite_award_emoji(note, new_note)
        end
      end

      def rewrite_content(content)
        return unless content

        rewriters = [Gitlab::Gfm::ReferenceRewriter, Gitlab::Gfm::UploadsRewriter]

        rewriters.inject(content) do |text, klass|
          rewriter = klass.new(text, old_project, current_user)
          rewriter.rewrite(new_parent)
        end
      end

      def rewrite_award_emoji(old_awardable, new_awardable)
        old_awardable.award_emoji.each do |award|
          new_award = award.dup
          new_award.awardable = new_awardable
          new_award.save
        end
      end
    end
  end
end
