module Github
  class Import
    class LegacyDiffNote < ::LegacyDiffNote
      self.table_name = 'notes'
      self.store_full_sti_class = false

      self.reset_callbacks :commit
      self.reset_callbacks :update
      self.reset_callbacks :validate
    end
  end
end
