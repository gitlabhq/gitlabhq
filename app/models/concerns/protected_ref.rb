# frozen_string_literal: true

module ProtectedRef
  extend ActiveSupport::Concern

  include Gitlab::Utils::StrongMemoize
  include Importable

  included do
    belongs_to :project, touch: true

    validates :name, presence: true

    delegate :matching, :matches?, :wildcard?, to: :ref_matcher

    scope :for_project, ->(project) { where(project: project) }
  end

  def commit
    project&.commit(name)
  end

  class_methods do
    def protected_ref_access_levels(*types)
      protected_ref = model_name.singular
      types.each do |type|
        access_levels_for_type = :"#{type}_access_levels"
        has_many access_levels_for_type, inverse_of: protected_ref
        accepts_nested_attributes_for access_levels_for_type, allow_destroy: true
      end
    end

    def protected_ref_accessible_to?(ref, user, project:, action:, protected_refs: nil)
      access_levels_for_ref(ref, action: action, protected_refs: protected_refs).any? do |access_level|
        access_level.check_access(user, project)
      end
    end

    def developers_can?(action, ref, protected_refs: nil)
      access_levels_for_ref(ref, action: action, protected_refs: protected_refs).any? do |access_level|
        access_level.access_level == Gitlab::Access::DEVELOPER
      end
    end

    def access_levels_for_ref(ref, action:, protected_refs: nil)
      matching(ref, protected_refs: protected_refs)
        .flat_map(&:"#{action}_access_levels")
    end

    # Returns all protected refs that match the given ref name.
    # This checks all records from the scope built up so far, and does
    # _not_ return a relation.
    #
    # This method optionally takes in a list of `protected_refs` to search
    # through, to avoid calling out to the database.
    def matching(ref_name, protected_refs: nil)
      (protected_refs || all).select { |protected_ref| protected_ref.matches?(ref_name) }
    end
  end

  private

  def ref_matcher
    strong_memoize_with(:ref_matcher, name) do
      RefMatcher.new(name)
    end
  end
end

# Prepending a module into a concern doesn't work very well for class methods,
# since these are defined in a ClassMethods constant. As such, we prepend the
# module directly into ProtectedRef::ClassMethods, instead of prepending it into
# ProtectedRef.
ProtectedRef::ClassMethods.prepend_mod_with('ProtectedRef')
