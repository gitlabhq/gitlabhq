# frozen_string_literal: true

module Routing
  module PseudonymizationHelper
    class MaskHelper
      QUERY_PARAMS_TO_MASK = %w[
        assignee_username
        author_username
      ].freeze

      def initialize(request_object, group, project)
        @request = request_object
        @group = group
        @project = project
      end

      def mask_params
        return default_root_url + @request.original_fullpath unless has_maskable_params?

        masked_params = @request.path_parameters.to_h do |key, value|
          case key
          when :project_id
            [key, "project#{@project&.id}"]
          when :namespace_id, :group_id
            namespace = @group || @project&.namespace
            [key, "namespace#{namespace&.id}"]
          when :id
            [key, mask_id(value)]
          else
            [key, value]
          end
        end

        generate_url(masked_params.merge(masked_query_params))
      end

      private

      def generate_url(masked_params)
        # The below check is added since `project/insights` route does not
        # work with Rails router `url_for` method.
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/343551
        if @request.path_parameters[:controller] == 'projects/insights'
          default_root_url + "#{Gitlab::Routing.url_helpers.namespace_project_insights_path(masked_params)}"
        elsif @request.path_parameters[:controller] == 'groups/insights'
          default_root_url + "#{Gitlab::Routing.url_helpers.group_insights_path(masked_params)}"
        else
          Gitlab::Routing.url_helpers.url_for(masked_params.merge(masked_query_params))
        end
      end

      def mask_id(value)
        if @request.path_parameters[:controller] == 'projects/blob'
          ':repository_path'
        elsif @request.path_parameters[:controller] == 'projects'
          "project#{@project&.id}"
        elsif @request.path_parameters[:controller] == 'groups'
          "namespace#{@group&.id}"
        else
          value
        end
      end

      def has_maskable_params?
        request_params = @request.path_parameters.to_h
        request_params.key?(:namespace_id) || request_params.key?(:group_id) || request_params.key?(:project_id) || request_params.key?(:id) || @request.query_string.present?
      end

      def masked_query_params
        return {} unless @request.query_string.present?

        query_string_hash = Rack::Utils.parse_nested_query(@request.query_string)

        QUERY_PARAMS_TO_MASK.each do |maskable_attribute|
          next unless query_string_hash.has_key?(maskable_attribute)

          query_string_hash[maskable_attribute] = "masked_#{maskable_attribute}"
        end

        query_string_hash
      end

      def default_root_url
        Gitlab::Routing.url_helpers.root_url(only_path: false)
      end
    end

    def masked_page_url
      return unless Feature.enabled?(:mask_page_urls, type: :ops)

      current_group = group if defined?(group)
      current_project = project if defined?(project)
      mask_helper = MaskHelper.new(request, current_group, current_project)
      mask_helper.mask_params

    # We rescue all exception for time being till we test this helper extensively.
    # Check https://gitlab.com/gitlab-org/gitlab/-/merge_requests/72864#note_711515501
    rescue => e # rubocop:disable Style/RescueStandardError
      Gitlab::ErrorTracking.track_exception(e, url: request.original_fullpath)
      nil
    end
  end
end
