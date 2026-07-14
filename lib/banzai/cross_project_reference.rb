# frozen_string_literal: true

module Banzai
  # Common methods for ReferenceFilters that support an optional cross-project
  # reference.
  module CrossProjectReference
    include Banzai::Filter::Concerns::ContextAccessors

    # Given a cross-project reference string, get the Project record
    #
    # Defaults to value of `context[:project]`, or `context[:group]` if:
    # * No reference is given OR
    # * Reference given doesn't exist
    #
    # ref - String reference.
    #
    # Returns a Project, or nil if the reference can't be found
    def parent_from_ref(ref)
      return project || group unless ref
      return project if project&.full_path == ref

      if reference_cache.cache_loaded?
        # optimization to reuse the parent_per_reference query information
        reference_cache.parent_per_reference[ref || reference_cache.current_parent_path]
      else
        Project.find_by_full_path(ref)
      end
    end
  end
end
