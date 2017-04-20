module ProtectedRef
  extend ActiveSupport::Concern

  included do
    belongs_to :project

    validates :name, presence: true
    validates :project, presence: true

    delegate :matching, :matches?, :wildcard?, to: :ref_matcher

    def self.protected_ref_accessible_to?(ref, user, action:)
      access_levels_for_ref(ref, action: action).any? do |access_level|
        access_level.check_access(user)
      end
    end

    def self.developers_can?(action, ref)
      access_levels_for_ref(ref, action: action).any? do |access_level|
        access_level.access_level == Gitlab::Access::DEVELOPER
      end
    end

    def self.access_levels_for_ref(ref, action:)
      self.matching(ref).map(&:"#{action}_access_levels").flatten
    end

    def self.matching(ref_name, protected_refs: nil)
      ProtectedRefMatcher.matching(self, ref_name, protected_refs: protected_refs)
    end
  end

  def commit
    project.commit(self.name)
  end

  private

  def ref_matcher
    @ref_matcher ||= ProtectedRefMatcher.new(self)
  end
end
