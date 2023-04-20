# frozen_string_literal: true

module Mutations
  module ContainerRepositories
    class DestroyBase < Mutations::BaseMutation
      include ::Mutations::PackageEventable
    end
  end
end
