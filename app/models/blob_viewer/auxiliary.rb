# frozen_string_literal: true

module BlobViewer
  module Auxiliary
    extend ActiveSupport::Concern

    include Gitlab::Allowable

    included do
      self.loading_partial_name = 'loading_auxiliary'
      self.type = :auxiliary
      self.collapse_limit = 100.kilobytes
      self.size_limit = 100.kilobytes
    end

    def visible_to?(current_user, ref)
      true
    end
  end
end
