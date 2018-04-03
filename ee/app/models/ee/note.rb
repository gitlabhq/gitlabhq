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

      super.merge(group: noteable.group)
    end
  end
end
