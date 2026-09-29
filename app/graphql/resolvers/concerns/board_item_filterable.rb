# frozen_string_literal: true

module BoardItemFilterable
  extend ActiveSupport::Concern

  private

  def item_filters(args)
    filters = args.to_h

    set_filter_values(filters)

    if filters[:not]
      set_filter_values(filters[:not])
      # `authorUsernames` is the additive multi-value negation argument; the
      # finder consumes the singular `author_username` (which accepts an array).
      rewrite_param_name(filters[:not], :author_usernames, :author_username)
    end

    if filters[:or]
      rewrite_param_name(filters[:or], :author_usernames, :author_username)
      rewrite_param_name(filters[:or], :assignee_usernames, :assignee_username)
      rewrite_param_name(filters[:or], :label_names, :label_name)
    end

    filters
  end

  def set_filter_values(filters)
    filter_by_assignee(filters)
  end

  def filter_by_assignee(filters)
    if filters[:assignee_username] && filters[:assignee_wildcard_id]
      raise ::Gitlab::Graphql::Errors::ArgumentError, 'Incompatible arguments: assigneeUsername, assigneeWildcardId.'
    end

    filters[:assignee_id] = filters.delete(:assignee_wildcard_id) if filters[:assignee_wildcard_id]
  end

  def rewrite_param_name(filters, old_name, new_name)
    filters[new_name] = filters.delete(old_name) if filters[old_name].present?
  end
end

::BoardItemFilterable.prepend_mod_with('Resolvers::BoardItemFilterable')
