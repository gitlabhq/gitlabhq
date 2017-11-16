module IssuableLinks
  class DestroyService < BaseService
    attr_reader :link, :current_user

    def initialize(link, user)
      @link = link
      @current_user = user
    end

    def execute
      return error('No Issue Link found', 404) unless permission_to_remove_relation?

      remove_relation
      create_notes if create_notes?

      success(message: 'Relation was removed')
    end

    private

    def create_notes
      SystemNoteService.unrelate_issue(source, target, current_user)
      SystemNoteService.unrelate_issue(target, source, current_user)
    end

    def remove_relation
      link.destroy!
    end

    def create_notes?
      true
    end
  end
end
