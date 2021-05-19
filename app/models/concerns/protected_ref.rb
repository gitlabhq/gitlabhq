# frozen_string_literal: true

module ProtectedRef
  extend ActiveSupport::Concern

  included do
    belongs_to :project, touch: true

    validates :name, presence: true
    validates :project, presence: true

    delegate :matching, :matches?, :wildcard?, to: :ref_matcher

    scope :for_project, ->(project) { where(project: project) }

    def allow_multiple?(type)
      false
    end
  end

  def commit
    project.commit(self.name)
  end

  class_methods do
    def protected_ref_access_levels(*types)
      types.each do |type|
        # We need to set `inverse_of` to make sure the `belongs_to`-object is set
        # when creating children using `accepts_nested_attributes_for`.
        #
        # If we don't `protected_branch` or `protected_tag` would be empty and
        # `project` cannot be delegated to it, which in turn would cause validations
        # to fail.
        has_many :"#{type}_access_levels", inverse_of: self.model_name.singular

        validates :"#{type}_access_levels", length: { is: 1, message: "are restricted to a single instance per #{self.model_name.human}." }, unless: -> { allow_multiple?(type) }

        accepts_nested_attributes_for :"#{type}_access_levels", allow_destroy: true
      end
    end

    def protected_ref_accessible_to?(ref, user, project:, action:, protected_refs: nil)
      access_levels_for_ref(ref, action: action, protected_refs: protected_refs).any? do |access_level|
        access_level.check_access(user)
      end
    end

    def developers_can?(action, ref, protected_refs: nil)
      access_levels_for_ref(ref, action: action, protected_refs: protected_refs).any? do |access_level|
        access_level.access_level == Gitlab::Access::DEVELOPER
      end
    end

    def access_levels_for_ref(ref, action:, protected_refs: nil)
      self.matching(ref, protected_refs: protected_refs)
        .flat_map(&:"#{action}_access_levels")
    end

    # Returns all protected refs that match the given ref name.
    # This checks all records from the scope built up so far, and does
    # _not_ return a relation.
    #
    # This method optionally takes in a list of `protected_refs` to search
    # through, to avoid calling out to the database.
    def matching(ref_name, protected_refs: nil)
      (protected_refs || self.all).select { |protected_ref| protected_ref.matches?(ref_name) }
    end
  end

  private

  def ref_matcher
    @ref_matcher ||= RefMatcher.new(self.name)
  end
end

# Prepending a module into a concern doesn't work very well for class methods,
# since these are defined in a ClassMethods constant. As such, we prepend the
# module directly into ProtectedRef::ClassMethods, instead of prepending it into
# ProtectedRef.
ProtectedRef::ClassMethods.prepend_mod_with('ProtectedRef')
