# frozen_string_literal: true

# TOOD: https://gitlab.com/gitlab-org/gitlab/-/issues/425379
# WARNING: This module has been deprecated.
# The module solely exists because ExtractsPath depends on this module (ExtractsPath is the only user.)
# ExtractsRef::RefExtractor class is a refactored version of this module and provides
# the same functionalities. You should use the class instead.
#
# Module providing methods for dealing with separating a tree-ish string and a
# file path string when combined in a request parameter
# Can be extended for different types of repository object, e.g. Project or Snippet
module ExtractsRef
  InvalidPathError = ExtractsRef::RefExtractor::InvalidPathError
  BRANCH_REF_TYPE = ExtractsRef::RefExtractor::BRANCH_REF_TYPE
  TAG_REF_TYPE = ExtractsRef::RefExtractor::TAG_REF_TYPE
  REF_TYPES = ExtractsRef::RefExtractor::REF_TYPES

  # Assigns common instance variables for views working with Git tree-ish objects
  #
  # Assignments are:
  #
  # - @id     - A string representing the joined ref and path
  # - @ref    - A string representing the ref (e.g., the branch, tag, or commit SHA)
  # - @path   - A string representing the filesystem path
  # - @commit - A Commit representing the commit from the given ref
  #
  # If the :id parameter appears to be requesting a specific response format,
  # that will be handled as well.
  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def assign_ref_vars
    ref_extractor = ExtractsRef::RefExtractor.new(repository_container, params.permit(:id, :ref, :path, :ref_type))
    ref_extractor.extract!

    @id = ref_extractor.id
    @ref = ref_extractor.ref
    @path = ref_extractor.path
    @repo = ref_extractor.repo

    return unless @ref.present?

    @commit = ref_extractor.commit
    @fully_qualified_ref = ref_extractor.fully_qualified_ref
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def ref_type
    ExtractsRef::RefExtractor.ref_type(params[:ref_type])
  end

  private

  def ref_names
    return [] unless repository_container

    @ref_names ||= repository_container.repository.ref_names # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  def repository_container
    raise NotImplementedError
  end
end
