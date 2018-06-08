module EE
  module Note
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include ObjectStorage::BackgroundMove
    end

    def for_epic?
      noteable.is_a?(Epic)
    end

    # Remove with https://gitlab.com/gitlab-org/gitlab-ee/issues/6347
    def note
      raw_note = super

      return raw_note unless system? && system_note_metadata&.action == 'weight'

      raw_note.delete(',')
    end

    # Remove with https://gitlab.com/gitlab-org/gitlab-ee/issues/6347
    def note_html
      raw_note_html = super

      return raw_note_html unless system? && system_note_metadata&.action == 'weight'

      raw_note_html.delete(',')
    end

    override :for_project_noteable?
    def for_project_noteable?
      !for_epic? && super
    end

    override :can_create_todo?
    def can_create_todo?
      !for_epic? && super
    end

    override :etag_key
    def etag_key
      if for_epic?
        return ::Gitlab::Routing.url_helpers.group_epic_notes_path(noteable.group, noteable)
      end

      super
    end

    override :banzai_render_context
    def banzai_render_context(field)
      return super unless for_epic?

      super.merge(banzai_context_params)
    end

    override :mentionable_params
    def mentionable_params
      return super unless for_epic?

      super.merge(banzai_context_params)
    end

    private

    def banzai_context_params
      { group: noteable.group, label_url_method: :group_epics_url }
    end
  end
end
