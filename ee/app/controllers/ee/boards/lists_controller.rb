module EE
  module Boards
    module ListsController
      extend ::Gitlab::Utils::Override

      override :list_creation_attrs
      def list_creation_attrs
        super + %i[assignee_id]
      end

      override :serialization_attrs
      def serialization_attrs
        super.merge(user: true)
      end
    end
  end
end
