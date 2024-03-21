# frozen_string_literal: true

module ExtractsRef
  class RequestedRef
    include Gitlab::Utils::StrongMemoize

    SYMBOLIC_REF_PREFIX = %r{((refs/)?(heads|tags)/)+}
    def initialize(repository, ref_type:, ref:)
      @ref_type = ref_type
      @ref = ref
      @repository = repository
    end

    attr_reader :repository, :ref_type, :ref

    def find
      case ref_type
      when 'tags'
        { ref_type: ref_type, commit: tag }
      when 'heads'
        { ref_type: ref_type, commit: branch }
      else
        commit_without_ref_type
      end
    end

    private

    def commit_without_ref_type
      if commit.nil?
        { ref_type: nil, commit: nil }
      elsif commit.id == ref
        # ref is probably complete 40 character sha
        { ref_type: nil, commit: commit }
      elsif tag.present?
        { ref_type: 'tags', commit: tag, ambiguous: branch.present? }
      elsif branch.present?
        { ref_type: 'heads', commit: branch }
      else
        { ref_type: nil, commit: commit, ambiguous: ref.match?(SYMBOLIC_REF_PREFIX) }
      end
    end

    def commit
      repository.commit(ref)
    end
    strong_memoize_attr :commit

    def tag
      return unless repository.tag_exists?(ref)

      raw_commit = repository.find_tag(ref)&.dereferenced_target
      ::Commit.new(raw_commit, repository.container) if raw_commit
    end
    strong_memoize_attr :tag

    def branch
      return unless repository.branch_exists?(ref)

      raw_commit = repository.find_branch(ref)&.dereferenced_target
      ::Commit.new(raw_commit, repository.container) if raw_commit
    end
    strong_memoize_attr :branch
  end
end
