module EE
  module Note
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include ObjectStorage::BackgroundMove
    end

    override :for_project_noteable?
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
  end
end
