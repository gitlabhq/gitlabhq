# frozen_string_literal: true

class ProtectedTag < ActiveRecord::Base
  include Gitlab::ShellAdapter
  include ProtectedRef
  include EE::ProtectedRef

  validates :name, uniqueness: { scope: :project_id }

  protected_ref_access_levels :create

  def self.protected?(project, ref_name)
    refs = project.protected_tags.select(:name)

    self.matching(ref_name, protected_refs: refs).present?
  end
end
