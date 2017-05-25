module BlobViewer
  module Auxiliary
    extend ActiveSupport::Concern

    include Gitlab::Allowable

    included do
      self.loading_partial_name = 'loading_auxiliary'
      self.type = :auxiliary
      self.overridable_max_size = 100.kilobytes
      self.max_size = 100.kilobytes
    end

    def visible_to?(current_user)
      true
    end
  end
end
