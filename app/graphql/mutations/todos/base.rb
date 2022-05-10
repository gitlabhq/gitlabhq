# frozen_string_literal: true

module Mutations
  module Todos
    class Base < ::Mutations::BaseMutation
      private

      def find_object(id:)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
