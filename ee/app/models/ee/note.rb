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

    override :for_issuable?
    def for_issuable?
      for_epic? || super
    end

    private

    def banzai_context_params
      { group: noteable.group, label_url_method: :group_epics_url }
    end
  end
end
