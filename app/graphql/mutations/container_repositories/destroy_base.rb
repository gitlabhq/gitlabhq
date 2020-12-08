# frozen_string_literal: true

module Mutations
  module ContainerRepositories
    class DestroyBase < Mutations::BaseMutation
      include ::Mutations::PackageEventable

      private

      def find_object(id:)
        # TODO: remove this line when the compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = ::Types::GlobalIDType[::ContainerRepository].coerce_isolated_input(id)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
