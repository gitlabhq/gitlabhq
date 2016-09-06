module ProtectedBranchAccess
  extend ActiveSupport::Concern

  included do
    scope :master, -> () { where(access_level: Gitlab::Access::MASTER) }
    scope :developer, -> () { where(access_level: Gitlab::Access::DEVELOPER) }
  end

  def humanize
    self.class.human_access_levels[self.access_level]
  end
end
