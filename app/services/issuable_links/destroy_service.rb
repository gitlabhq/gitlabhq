# frozen_string_literal: true

module IssuableLinks
  class DestroyService < BaseService
    attr_reader :link, :current_user, :source, :target

    def initialize(link, user)
      @link = link
      @current_user = user
      @source = link.source
      @target = link.target
    end

    def execute
      return error(not_found_message, 404) unless permission_to_remove_relation?

      remove_relation
      after_destroy

      success(message: 'Relation was removed')
    end

    private

    def create_notes
      SystemNoteService.unrelate_issuable(source, target, current_user)
      SystemNoteService.unrelate_issuable(target, source, current_user)
    end

    def after_destroy
      create_notes
      track_event
    end

    def remove_relation
      link.destroy!
    end

    def not_found_message
      'No Issue Link found'
    end

    def track_event
      # no op
    end
  end
end
