# frozen_string_literal: true

module SnippetsSort
  extend ActiveSupport::Concern

  def sort_param
    pagination_params[:sort].presence || 'updated_desc'
  end
end
