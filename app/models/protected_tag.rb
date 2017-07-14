class ProtectedTag < ActiveRecord::Base
  include Gitlab::ShellAdapter
  include ProtectedRef
  include EE::ProtectedRef

  protected_ref_access_levels :create

  def self.protected?(project, ref_name)
    self.matching(ref_name, protected_refs: project.protected_tags).present?
  end
end
