# frozen_string_literal: true

module Mutations
  module AuthorizesProject
    include ResolvesProject

    def authorized_find_project!(full_path:)
      authorized_find!(full_path: full_path)
    end

    private

    def find_object(full_path:)
      resolve_project(full_path: full_path)
    end
  end
end
