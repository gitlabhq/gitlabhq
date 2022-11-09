# frozen_string_literal: true

# Distinguish between a top level query and a subselect.
#
# Retrieve column values when the relation has already been loaded, otherwise reselect the relation.
# Useful for preload query patterns where the typical Rails #preload does not fit. Such as:
#
# projects = Project.where(...)
# projects.load
# ...
# options[members] = ProjectMember.where(...).where(source_id: projects.select(:id))
module Subquery
  extend ActiveSupport::Concern

  class_methods do
    def subquery(*column_names, max_limit: 5_000)
      if current_scope.loaded? && current_scope.size <= max_limit
        current_scope.pluck(*column_names)
      else
        current_scope.reselect(*column_names)
      end
    end
  end
end
