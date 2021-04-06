# frozen_string_literal: true

module IssuableLinks
  class DestroyService < BaseService
    include IncidentManagement::UsageData

    attr_reader :link, :current_user

    def initialize(link, user)
      @link = link
      @current_user = user
    end

    def execute
      return error(not_found_message, 404) unless permission_to_remove_relation?

      remove_relation
      after_destroy

      success(message: 'Relation was removed')
    end

    private

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
  end
end
