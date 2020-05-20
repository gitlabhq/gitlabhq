# frozen_string_literal: true

module Issuable
  module Clone
    class BaseService < IssuableBaseService
      attr_reader :original_entity, :new_entity

      alias_method :old_project, :project

      def execute(original_entity, new_project = nil)
        @original_entity = original_entity

        # Using transaction because of a high resources footprint
        # on rewriting notes (unfolding references)
        #
        ActiveRecord::Base.transaction do
          @new_entity = create_new_entity

          update_new_entity
          update_old_entity
          create_notes
        end
      end

      private

      def update_new_entity
        rewriters = [ContentRewriter, AttributesRewriter]

        rewriters.each do |rewriter|
          rewriter.new(current_user, original_entity, new_entity).execute
        end
      end

      def update_old_entity
        close_issue
      end

      def create_notes
        add_note_from
        add_note_to
      end

      def close_issue
        close_service = Issues::CloseService.new(old_project, current_user)
        close_service.execute(original_entity, notifications: false, system_note: false)
      end

      def new_parent
        new_entity.project || new_entity.group
      end

      def group
        if new_entity.project&.group && current_user.can?(:read_group, new_entity.project.group)
          new_entity.project.group
        end
      end
    end
  end
end

Issuable::Clone::BaseService.prepend_if_ee('EE::Issuable::Clone::BaseService')
