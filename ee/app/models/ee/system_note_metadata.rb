module EE
  module SystemNoteMetadata
    extend ::Gitlab::Utils::Override

    EE_ICON_TYPES = %w[
      weight approved unapproved relate unrelate
      epic_issue_added issue_added_to_epic epic_issue_removed issue_removed_from_epic
      epic_issue_moved issue_changed_epic epic_date_changed
    ].freeze

    override :icon_types
    def icon_types
      @icon_types ||= (super + EE_ICON_TYPES).freeze
    end
  end
end
