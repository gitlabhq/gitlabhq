# frozen_string_literal: true

module Mutations
  module ResolvesIssuable
    extend ActiveSupport::Concern

    included do
      include ResolvesProject
    end

    def resolve_issuable(type:, parent_path:, iid:)
      parent = ::Gitlab::Graphql::Lazy.force(resolve_issuable_parent(type, parent_path))
      return unless parent.present?

      finder = issuable_finder(type, iids: [iid])
      Gitlab::Graphql::Loaders::IssuableLoader.new(parent, finder).find_all.first
    end

    private

    def issuable_finder(type, args)
      case type
      when :merge_request
        MergeRequestsFinder.new(current_user, args)
      when :issue
        IssuesFinder.new(current_user, args)
      else
        raise "Unsupported type: #{type}"
      end
    end

    def resolve_issuable_parent(type, parent_path)
      return unless parent_path.present?
      return unless type == :issue || type == :merge_request

      resolve_project(full_path: parent_path)
    end
  end
end

Mutations::ResolvesIssuable.prepend_mod_with('Mutations::ResolvesIssuable')
