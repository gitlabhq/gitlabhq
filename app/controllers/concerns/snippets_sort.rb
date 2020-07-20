# frozen_string_literal: true

module SnippetsSort
  extend ActiveSupport::Concern

  def sort_param
    params[:sort].presence || 'updated_desc'
  end
end
