# frozen_string_literal: true

module Mutations
  module ResolvesProject
    extend ActiveSupport::Concern

    def resolve_project(full_path:)
      project_resolver.resolve(full_path: full_path)
    end

    def project_resolver
      Resolvers::ProjectResolver.new(object: nil, context: context, field: nil)
    end
  end
end
