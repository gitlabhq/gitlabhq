# frozen_string_literal: true

module API
  module Helpers
    class WorkItemsFilterParams
      attr_reader :params, :resource_parent

      def initialize(params, resource_parent: nil)
        @params = params
        @resource_parent = resource_parent
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
        transformed[:non_archived] = !transformed.delete(:include_archived) if transformed.key?(:include_archived)

        transformed[:in] = transformed[:in].join(',') if transformed[:in].present?

        if transformed[:timeframe]
          transformed[:start_date] = transformed.dig(:timeframe, :start)
          transformed[:end_date] = transformed.dig(:timeframe, :end)
          transformed.delete(:timeframe)
        end

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

API::Helpers::WorkItemsFilterParams.prepend_mod
