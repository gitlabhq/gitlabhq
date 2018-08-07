module EE
  module Boards
    module ListsController
      extend ::Gitlab::Utils::Override

      override :list_creation_attrs
      def list_creation_attrs
        super + %i[assignee_id milestone_id]
      end

      override :serialization_attrs
      def serialization_attrs
        super.merge(user: true, milestone: true)
      end
    end
  end
end
