# frozen_string_literal: true

module Mutations
  module ContainerRepositories
    class DestroyBase < Mutations::BaseMutation
      include ::Mutations::PackageEventable

      private

      def find_object(id:)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
