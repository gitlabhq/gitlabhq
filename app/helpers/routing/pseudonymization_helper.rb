# frozen_string_literal: true

module Routing
  module PseudonymizationHelper
    PSEUDONOMIZED_NAMESPACE = "namespace"
    PSEUDONOMIZED_PROJECT = "project"
    PSEUDONOMIZED_GROUP = "group"
    PSEUDONOMIZED_ID = "id"

    class MaskHelper
      QUERY_PARAMS_TO_NOT_MASK = %w[
        scope
        severity
        sortBy
        sortDesc
        state
        tab
        glm_source
        glm_content
        _gl
        utm_medium
        utm_source
        utm_campaign
        utm_content
        utm_budget
      ].freeze

      def initialize(request_object, group, project)
        @request = request_object
        @group = group
        @project = project
      end

      def mask_params
        return @request.original_url unless has_maskable_params?

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

        Gitlab::Routing.url_helpers.url_for(masked_params.merge(params: masked_query_params))
      end

      private

      def mask_id(value)
        case @request.path_parameters[:controller]
        when 'projects/blob'
          ':repository_path'
        when 'projects'
          "project#{@project&.id}"
        when 'groups'
          "namespace#{@group&.id}"
        else
          value
        end
      end

      def has_maskable_params?
        request_params = @request.path_parameters.to_h
        request_params.key?(:namespace_id) ||
          request_params.key?(:group_id) ||
          request_params.key?(:project_id) ||
          request_params.key?(:id) ||
          @request.query_string.present?
      end

      def masked_query_params
        return {} unless @request.query_string.present?

        query_string_hash = Rack::Utils.parse_nested_query(@request.query_string)

        query_string_hash.keys.each do |key|
          next if QUERY_PARAMS_TO_NOT_MASK.include?(key)

          query_string_hash[key] = "masked_#{key}"
        end

        query_string_hash
      end
    end

    def masked_page_url(group:, project:)
      return unless Feature.enabled?(:mask_page_urls, type: :ops)

      mask_helper = MaskHelper.new(request, group, project)
      mask_helper.mask_params

    # We rescue all exception for time being till we test this helper extensively.
    # Check https://gitlab.com/gitlab-org/gitlab/-/merge_requests/72864#note_711515501
    rescue => e # rubocop:disable Style/RescueStandardError
      Gitlab::ErrorTracking.track_exception(e, url: request.original_fullpath)
      nil
    end

    def masked_referrer_url(url)
      return unless url

      params = referrer_params(url)

      return unless params && params[:controller]
      return if params[:action] == "route_not_found"

      original_id = params[:id]

      case params[:controller]
      when 'groups'
        params[:id] = PSEUDONOMIZED_NAMESPACE
      when 'projects'
        params[:id] = PSEUDONOMIZED_PROJECT
      else
        params[:id] = PSEUDONOMIZED_ID if params[:id]
      end

      params[:project_id] = PSEUDONOMIZED_PROJECT if params[:project_id]
      params[:group_id] = PSEUDONOMIZED_GROUP if params[:group_id]
      params[:namespace_id] = PSEUDONOMIZED_NAMESPACE if params[:namespace_id]

      masked_query_params = masked_query_params(URI.parse(url))

      Gitlab::Routing.url_helpers.url_for(params.merge(params: masked_query_params))
    rescue ActionController::UrlGenerationError
      # If URL cannot be constructed with placeholder, use original ID
      params[:id] = original_id
      Gitlab::Routing.url_helpers.url_for(params.merge(params: masked_query_params))
    end

    def masked_query_params(uri)
      query_params = CGI.parse(uri.query.to_s)
      query_params.transform_keys!(&:downcase)

      return if query_params.empty?

      query_params.each do |key, _|
        query_params[key] = ["masked_#{key}"] unless MaskHelper::QUERY_PARAMS_TO_NOT_MASK.include?(key)
      end

      query_params
    end

    def referrer_params(url)
      Rails.application.routes.recognize_path(url)
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e, url: request.original_fullpath)
      nil
    end
  end
end
