# frozen_string_literal: true

module Mutations
  module ResolvesIssuable
    extend ActiveSupport::Concern

    included do
      include ResolvesProject
    end

    def resolve_issuable(type:, parent_path:, iid:)
      parent = resolve_issuable_parent(type, parent_path)
      key = type == :merge_request ? :iids : :iid
      args = { key => iid.to_s }

      resolver = issuable_resolver(type, parent, context)
      ready, early_return = resolver.ready?(**args)

      return early_return unless ready

      resolver.resolve(**args)
    end

    private

    def issuable_resolver(type, parent, context)
      resolver_class = "Resolvers::#{type.to_s.classify.pluralize}Resolver".constantize

      resolver_class.single.new(object: parent, context: context, field: nil)
    end

    def resolve_issuable_parent(type, parent_path)
      return unless type == :issue || type == :merge_request

      resolve_project(full_path: parent_path) if parent_path.present?
    end
  end
end

Mutations::ResolvesIssuable.prepend_if_ee('::EE::Mutations::ResolvesIssuable')
