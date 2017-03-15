class ProtectedTag < ActiveRecord::Base
  include Gitlab::ShellAdapter

  belongs_to :project
  validates :name, presence: true
  validates :project, presence: true

  has_many :push_access_levels, dependent: :destroy

  validates :push_access_levels, length: { is: 1, message: "are restricted to a single instance per protected tag." }

  accepts_nested_attributes_for :push_access_levels

  def commit
    project.commit(self.name)
  end

  def self.matching(tag_name, protected_tags: nil)
    ProtectedRefMatcher.matching(ProtectedTag, tag_name, protected_refs: protected_tags)
  end

  def matching(branches)
    ref_matcher.matching(branches)
  end

  def matches?(tag_name)
    ref_matcher.matches?(tag_name)
  end

  def wildcard?
    ref_matcher.wildcard?
  end

  private

  def ref_matcher
    @ref_matcher ||= ProtectedRefMatcher.new(self)
  end
end
