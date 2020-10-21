# frozen_string_literal: true

module Mutations
  module Todos
    class Base < ::Mutations::BaseMutation
      private

      def find_object(id:)
        # TODO: remove this line when the compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = ::Types::GlobalIDType[::Todo].coerce_isolated_input(id)
        GitlabSchema.find_by_gid(id)
      end

      def map_to_global_ids(ids)
        return [] if ids.blank?

        ids.map { |id| to_global_id(id) }
      end

      def to_global_id(id)
        Gitlab::GlobalId.as_global_id(id, model_name: Todo.name).to_s
      end
    end
  end
end
