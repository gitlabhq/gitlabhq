# frozen_string_literal: true

module Mutations
  module Todos
    class Base < ::Mutations::BaseMutation
      private

      def find_object(id:)
        GitlabSchema.object_from_id(id)
      end

      def to_global_id(id)
        ::URI::GID.build(app: GlobalID.app, model_name: Todo.name, model_id: id, params: nil).to_s
      end
    end
  end
end
