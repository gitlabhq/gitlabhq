# frozen_string_literal: true

module MergeRequests
  module AssignsMergeParams
    def self.included(klass)
      raise "#{self} can not be included in #{klass} without implementing #current_user" unless klass.method_defined?(:current_user)
    end

    def assign_allowed_merge_params(merge_request, merge_params)
      known_merge_params = merge_params.to_h.with_indifferent_access.slice(*MergeRequest::KNOWN_MERGE_PARAMS)

      # Not checking `MergeRequest#can_remove_source_branch` as that includes
      # other checks that aren't needed here.
      known_merge_params.delete(:force_remove_source_branch) unless current_user.can?(:push_code, merge_request.source_project)

      merge_request.merge_params.merge!(known_merge_params)

      # Delete the known params now that they're assigned, so we don't try to
      # assign them through an `#assign_attributes` later.
      # They could be coming in as strings or symbols
      merge_params.to_h.with_indifferent_access.except!(*MergeRequest::KNOWN_MERGE_PARAMS)
    end
  end
end
