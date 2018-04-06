module EE
  module NotesHelper
    extend ::Gitlab::Utils::Override

    override :notes_url
    def notes_url(params = {})
      return group_epic_notes_path(@epic.group, @epic) if @epic.is_a?(Epic)

      super
    end

    override :discussions_path
    def discussions_path(issuable)
      return discussions_group_epic_path(issuable.group, issuable, format: :json) if issuable.is_a?(Epic)

      super
    end
  end
end
