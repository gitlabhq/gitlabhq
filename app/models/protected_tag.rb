class ProtectedTag < ActiveRecord::Base
  include Gitlab::ShellAdapter
  include ProtectedRef

  has_many :create_access_levels, dependent: :destroy

  validates :create_access_levels, length: { is: 1, message: "are restricted to a single instance per protected tag." }

  accepts_nested_attributes_for :create_access_levels

  def self.protected?(project, ref_name)
    self.matching(ref_name, protected_refs: project.protected_tags).present?
  end
end
