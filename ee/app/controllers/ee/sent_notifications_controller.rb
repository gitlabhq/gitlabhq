module EE
  module SentNotificationsController
    extend ::Gitlab::Utils::Override

    private

    override :noteable_path
    def noteable_path(noteable)
      return epic_path(noteable) if noteable.is_a?(Epic)

      super
    end
  end
end
