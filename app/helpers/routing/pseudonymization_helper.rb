# frozen_string_literal: true

module Routing
  module PseudonymizationHelper
    def masked_page_url
      return unless Feature.enabled?(:mask_page_urls, type: :ops)

      mask_params(Rails.application.routes.recognize_path(request.original_fullpath))
    rescue ActionController::RoutingError, URI::InvalidURIError => e
      Gitlab::ErrorTracking.track_exception(e, url: request.original_fullpath)
      nil
    end

    private

    def mask_params(request_params)
      return if request_params[:action] == 'new'

      namespace_type = request_params[:controller].split('/')[1]

      namespace_type.present? ? url_with_namespace_type(request_params, namespace_type) : url_without_namespace_type(request_params)
    end

    def url_without_namespace_type(request_params)
      masked_url = "#{request.protocol}#{request.host_with_port}"

      masked_url += case request_params[:controller]
                    when 'groups'
                      "/namespace:#{group.id}"
                    when 'projects'
                      "/namespace:#{project.namespace.id}/project:#{project.id}"
                    when 'root'
                      ''
                    else
                      "#{request.path}"
                    end

      masked_url += request.query_string.present? ? "?#{request.query_string}" : ''

      masked_url
    end

    def url_with_namespace_type(request_params, namespace_type)
      masked_url = "#{request.protocol}#{request.host_with_port}"

      if request_params.has_key?(:project_id)
        masked_url += "/namespace:#{project.namespace.id}/project:#{project.id}/-/#{namespace_type}"
      end

      if request_params.has_key?(:id)
        masked_url += namespace_type == 'blob' ? '/:repository_path' : "/#{request_params[:id]}"
      end

      masked_url += request.query_string.present? ? "?#{request.query_string}" : ''

      masked_url
    end
  end
end
