module EE
  module Notes
    module BuildService
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      override :noteable_without_project?
      def noteable_without_project?(noteable)
        return true if noteable.is_a?(Epic) && can?(current_user, :create_note, noteable)

        super
      end
    end
  end
end
