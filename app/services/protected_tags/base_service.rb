# frozen_string_literal: true

module ProtectedTags
  class BaseService < ::BaseService
    include ProtectedRefNameSanitizer

    private

    def filtered_params
      return unless params

      params[:name] = sanitize_name(params[:name]) if params[:name].present?
      params
    end
  end
end
