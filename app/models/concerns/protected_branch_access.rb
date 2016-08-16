module ProtectedBranchAccess
  extend ActiveSupport::Concern

  def humanize
    self.class.human_access_levels[self.access_level]
  end
end
