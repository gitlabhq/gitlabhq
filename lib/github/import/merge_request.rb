module Github
  class Import
    class MergeRequest < ::MergeRequest
      self.table_name = 'merge_requests'

      self.reset_callbacks :create
      self.reset_callbacks :save
      self.reset_callbacks :commit
      self.reset_callbacks :update
      self.reset_callbacks :validate
    end
  end
end
