# frozen_string_literal: true

module Issuable
  class RelatedLinksCreateWorker
    include ApplicationWorker

    data_consistency :delayed

    sidekiq_options retry: 3

    feature_category :portfolio_management
    worker_resource_boundary :unknown
    urgency :high
    idempotent!

    def perform(args)
      @params = args.with_indifferent_access
      @user = User.find_by_id(params[:user_id])
      @issuable = issuable_class.find_by_id(params[:issuable_id])
      @links = issuable_class.related_link_class&.where(id: params[:link_ids])
      return unless user && issuable && links.present?

      create_issuable_notes!
    rescue ArgumentError => error
      logger.error(
        worker: self.class.name,
        message: "Failed to complete job (user_id:#{params[:user_id]}, issuable_id:#{params[:issuable_id]}, " \
                 "issuable_class:#{params[:issuable_class]}): #{error.message}"
      )
    end

    private

    attr_reader :params, :user, :issuable, :links

    def issuable_class
      params[:issuable_class].constantize
    rescue NameError
      raise ArgumentError, "Unknown class '#{params[:issuable_class]}'"
    end

    def create_issuable_notes!
      errors = create_notes.compact
      return unless errors.any?

      raise ArgumentError, "Could not create notes: #{errors.join(', ')}"
    end

    def create_notes
      linked_item_notes_errors = links.filter_map { |link| create_system_note(link.target, issuable) }
      issuable_note_error = create_system_note(issuable, links.collect(&:target))

      linked_item_notes_errors << issuable_note_error
    end

    def create_system_note(noteable, references, method_name = :relate_issuable)
      note = ::SystemNoteService.try(method_name, noteable, references, user)
      return if note.present?

      "{noteable_id: #{noteable.id}, reference_ids: #{[references].flatten.collect(&:id)}}"
    end
  end
end

Issuable::RelatedLinksCreateWorker.prepend_mod_with('Issuable::RelatedLinksCreateWorker')
