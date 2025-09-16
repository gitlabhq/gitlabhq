# frozen_string_literal: true

module Banzai
  module CrossNamespaceReference
    # Given a cross-namespace reference string, get the Namespace record.
    #
    # Defaults to value of `context[:project]`, or `context[:group]` if:
    # * No reference is given OR
    # * Reference given doesn't exist
    #
    # ref - String reference.
    #
    # Returns a Namespace or Project, or nil if the reference can't be found
    def parent_from_ref(ref)
      return context[:project] || context[:group] unless ref
      return context[:project] if context[:project]&.full_path == ref
      return context[:group] if context[:group]&.full_path == ref

      if reference_cache.cache_loaded?
        # optimization to reuse the parent_per_reference query information
        reference_cache.parent_per_reference[ref || reference_cache.current_parent_path]
      else
        Namespace.find_by_full_path(ref) || Project.find_by_full_path(ref)
      end
    end
  end
end
