# frozen_string_literal: true

module Mutations
  module ResolvesIssuable
    extend ActiveSupport::Concern
    include Mutations::ResolvesProject

    def resolve_issuable(type:, parent_path:, iid:)
      parent = resolve_issuable_parent(parent_path)

      issuable_resolver(type, parent, context).resolve(iid: iid.to_s)
    end

    def issuable_resolver(type, parent, context)
      resolver_class = "Resolvers::#{type.to_s.classify.pluralize}Resolver".constantize

      resolver_class.single.new(object: parent, context: context, field: nil)
    end

    def resolve_issuable_parent(parent_path)
      resolve_project(full_path: parent_path)
    end
  end
end
