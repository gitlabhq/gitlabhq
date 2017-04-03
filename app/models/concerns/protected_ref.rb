module ProtectedRef
  extend ActiveSupport::Concern

  included do
    belongs_to :project
    validates :name, presence: true
    validates :project, presence: true

    def self.matching_refs_accesible_to(ref, user, action: :push)
      access_levels_for_ref(ref, action).any? do |access_level|
        access_level.check_access(user)
      end
    end

    def self.access_levels_for_ref(ref, action: :push)
      self.matching(ref).map(&:"@#{action}_access_levels").flatten
    end

    private

    def self.matching(ref_name, protected_refs: nil)
      ProtectedRefMatcher.matching(self, ref_name, protected_refs: protected_refs)
    end
  end

  def commit
    project.commit(self.name)
  end

  def matching(refs)
    ref_matcher.matching(refs)
  end

  def matches?(refs)
    ref_matcher.matches?(refs)
  end

  def wildcard?
    ref_matcher.wildcard?
  end

  private

  def ref_matcher
    @ref_matcher ||= ProtectedRefMatcher.new(self)
  end
end
