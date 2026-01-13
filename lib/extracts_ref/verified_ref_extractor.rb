# frozen_string_literal: true

module ExtractsRef # rubocop:disable Gitlab/BoundedContexts -- This module already exists
  class VerifiedRefExtractor
    include Gitlab::Utils::StrongMemoize

    SYMBOLIC_REF_PREFIX = %r{((refs/)?(heads|tags)/)+}

    class << self
      def ref_type(...)
        new(...).ref_type
      end

      def ambiguous_ref?(...)
        new(...).ambiguous_ref?
      end
    end

    def initialize(repository, ref_type:, ref:)
      @ref_type = RefExtractor.ref_type(ref_type)
      @ref = ref
      @repository = repository
    end

    attr_reader :repository, :ref

    def ref_type
      @ref_type || detect_ref_type
    end

    def ambiguous_ref?
      return false if @ref_type
      # We ignore branches with names matching commit SHAs so we can treat
      # these as unambiguous
      return false if commit_exists?
      return true if tag_exists? && branch_exists?

      # If a ref starts with refs/heads/, heads/, refs/tags/, or tags/ we treat
      # these as ambiguous because they could be `refs/heads/...` or
      # `refs/heads/refs/heads/...`
      ref.match?(SYMBOLIC_REF_PREFIX)
    end

    private

    def detect_ref_type
      return if commit_exists? || ambiguous_ref?

      return 'tags' if tag_exists?

      'heads' if branch_exists?
    end

    # This method behave differently when the ref is short_sha. Unfortunately
    # git behaves differently if a branch or tag exists with a name matching a
    # short_sha or full_sha:
    #
    ## Full SHA
    #
    # 1. branch/tag exists         -> repository.commit(ref).sha == ref
    # 2. branch/tag does not exist -> repository.commit(ref).sha == ref
    #
    ## Short SHA
    #
    # 1. branch/tag exists         -> repository.commit(ref).short_sha == ref
    # 2. branch/tag does not exist -> repository.commit(ref).short_sha != ref
    #
    # This happens because git treats the branch as a better match if a
    # short_sha is passed and a branch exists with that name.
    #
    def commit_exists?
      Gitlab::Git.commit_id?(ref) && repository.commit(ref)&.sha == ref
    end
    strong_memoize_attr :commit_exists?

    def tag_exists?
      repository.tag_exists?(ref)
    end
    strong_memoize_attr :tag_exists?

    def branch_exists?
      repository.branch_exists?(ref)
    end
    strong_memoize_attr :branch_exists?
  end
end
