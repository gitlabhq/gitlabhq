# frozen_string_literal: true

module ResolvesGroup # rubocop:disable Gitlab/BoundedContexts -- for consistency with existing groups resolver concern
  extend ActiveSupport::Concern

  def resolve_group(full_path:)
    group_resolver.resolve(full_path: full_path)
  end

  def group_resolver
    Resolvers::GroupResolver.new(object: nil, context: context, field: nil)
  end
end
