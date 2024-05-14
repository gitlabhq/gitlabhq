# frozen_string_literal: true

module WorkItems
  module RelatedWorkItemLinks
    class DestroyService < BaseService
      def initialize(work_item, user, params)
        @work_item = work_item
        @current_user = user
        @params = params.dup
        @failed_ids = []
        @removed_ids = []
      end

      def execute
        return error(_('No work item found.'), 403) unless can_admin_work_item_link?(work_item)
        return error(_('No work item IDs provided.'), 409) if params[:item_ids].empty?

        destroy_links_for(params[:item_ids])

        if removed_ids.any?
          success(message: response_message, items_removed: removed_ids, items_with_errors: failed_ids.flatten)
        else
          error(error_message)
        end
      end

      private

      attr_reader :work_item, :current_user, :failed_ids, :removed_ids

      def can_admin_work_item_link?(resource)
        can?(current_user, :admin_work_item_link, resource)
      end

      def destroy_links_for(item_ids)
        destroy_links(source: work_item, target: item_ids, direction: :target)
        destroy_links(source: item_ids, target: work_item, direction: :source)
      end

      def destroy_links(source:, target:, direction:)
        WorkItems::RelatedWorkItemLink.for_source_and_target(source, target).each do |link|
          linked_item = link.try(direction)

          if can_admin_work_item_link?(linked_item)
            create_notes(link) if perform_destroy_link(link, linked_item)
          else
            failed_ids << linked_item.id
          end
        end
      end

      # Overriden on EE to sync deletion with
      # related epic links records
      def perform_destroy_link(link, linked_item)
        link.destroy!
        removed_ids << linked_item.id
        true
      end

      def create_notes(link)
        SystemNoteService.unrelate_issuable(link.source, link.target, current_user)
        SystemNoteService.unrelate_issuable(link.target, link.source, current_user)
      end

      def error_message
        not_linked = params[:item_ids] - (removed_ids + failed_ids)
        error_messages = []

        if failed_ids.any?
          error_messages << format(
            _('%{item_ids} could not be removed due to insufficient permissions'), item_ids: failed_ids.to_sentence
          )
        end

        if not_linked.any?
          error_messages << format(
            _('%{item_ids} could not be removed due to not being linked'), item_ids: not_linked.to_sentence
          )
        end

        return '' unless error_messages.any?

        format(_('IDs with errors: %{error_messages}.'), error_messages: error_messages.join(', '))
      end

      def response_message
        success_message = format(_('Successfully unlinked IDs: %{item_ids}.'), item_ids: removed_ids.to_sentence)

        return success_message unless error_message.present?

        "#{success_message} #{error_message}"
      end
    end
  end
end

WorkItems::RelatedWorkItemLinks::DestroyService.prepend_mod_with('WorkItems::RelatedWorkItemLinks::DestroyService')
