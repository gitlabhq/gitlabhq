# frozen_string_literal: true

module BoardIssueFilterable
  extend ActiveSupport::Concern

  private

  def issue_filters(args)
    filters = args.to_h
    set_filter_values(filters)

    if filters[:not]
      filters[:not] = filters[:not].to_h
      set_filter_values(filters[:not])
    end

    filters
  end

  def set_filter_values(filters)
  end
end

::BoardIssueFilterable.prepend_if_ee('::EE::Resolvers::BoardIssueFilterable')
