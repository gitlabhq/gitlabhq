# frozen_string_literal: true

module Issuable
  module Clone
    class BaseService < IssuableBaseService
      attr_reader :original_entity, :new_entity, :target_project

      alias_method :old_project, :project

      def execute(original_entity, target_project = nil)
        @original_entity = original_entity
        @target_project = target_project

        # Using transaction because of a high resources footprint
        # on rewriting notes (unfolding references)
        #
        ApplicationRecord.transaction do
          @new_entity = create_new_entity

          update_new_entity
          update_old_entity
          create_notes
        end
      end

      private

      def rewritten_old_entity_attributes(include_milestone: true)
        Gitlab::Issuable::Clone::AttributesRewriter.new(
          current_user,
          original_entity,
          target_project
        ).execute(include_milestone: include_milestone)
      end

      def update_new_entity
        update_new_entity_description
        copy_award_emoji
        copy_notes
        copy_resource_events
      end

      def update_new_entity_description
        update_description_params = MarkdownContentRewriterService.new(
          current_user,
          original_entity,
          :description,
          original_entity.project,
          new_parent
        ).execute

        new_entity.update!(update_description_params)
      end

      def copy_award_emoji
        AwardEmojis::CopyService.new(original_entity, new_entity).execute
      end

      def copy_notes
        Notes::CopyService.new(current_user, original_entity, new_entity).execute
      end

      def copy_resource_events
        Gitlab::Issuable::Clone::CopyResourceEventsService.new(current_user, original_entity, new_entity).execute
      end

      def update_old_entity
        close_issue
      end

      def create_notes
        add_note_from
        add_note_to
      end

      def close_issue
        close_service = Issues::CloseService.new(project: old_project, current_user: current_user)
        close_service.execute(original_entity, notifications: false, system_note: true)
      end

      def new_parent
        new_entity.resource_parent
      end

      def relative_position
        return if original_entity.project.root_ancestor.id != target_project.root_ancestor.id

        original_entity.relative_position
      end
    end
  end
end

Issuable::Clone::BaseService.prepend_mod_with('Issuable::Clone::BaseService')
