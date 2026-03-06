# frozen_string_literal: true

module API
  module Helpers
    class WorkItemsFilterParams
      attr_reader :params

      def initialize(params)
        @params = params
      end

      def transform
        return {} if params.blank?

        transformed = params.to_h.deep_symbolize_keys

        rewrite_param_name(transformed, :assignee_usernames, :assignee_username)
        rewrite_param_name(transformed, :assignee_wildcard_id, :assignee_id)
        rewrite_param_name(transformed, :types, :issue_types)
        rewrite_param_name(transformed, :parent_ids, :work_item_parent_ids)

        rewrite_param_name(transformed[:not], :assignee_usernames, :assignee_username)
        rewrite_param_name(transformed[:not], :types, :issue_types)
        rewrite_param_name(transformed[:not], :parent_ids, :work_item_parent_ids)

        rewrite_param_name(transformed[:or], :assignee_usernames, :assignee_username)
        rewrite_param_name(transformed[:or], :author_usernames, :author_username)
        rewrite_param_name(transformed[:or], :label_names, :label_name)

        rewrite_param_name(transformed, :release_tag_wildcard_id, :release_tag)

        transformed
      end

      private

      def rewrite_param_name(hash, old_key, new_key)
        return unless hash.is_a?(Hash) && hash.key?(old_key)

        hash[new_key] = hash.delete(old_key)
      end
    end
  end
end
