# frozen_string_literal: true

module DesignManagement
  class DesignCollection
    attr_reader :issue

    delegate :designs, :project, to: :issue
    delegate :empty?, to: :designs

    state_machine :copy_state, initial: :ready, namespace: :copy do
      after_transition any => any, do: :update_stored_copy_state!

      event :start do
        transition ready: :in_progress
      end

      event :end do
        transition in_progress: :ready
      end

      event :error do
        transition in_progress: :error
      end

      event :reset do
        transition any => :ready
      end
    end

    def initialize(issue)
      super() # Necessary to initialize state_machine

      @issue = issue

      if stored_copy_state = get_stored_copy_state
        @copy_state = stored_copy_state
      end
    end

    def ==(other)
      other.is_a?(self.class) && issue == other.issue
    end

    def find_or_create_design!(filename:)
      designs.find { |design| design.filename == filename } ||
        designs.safe_find_or_create_by!(project: project, filename: filename)
    end

    def versions
      @versions ||= DesignManagement::Version.for_designs(designs)
    end

    def repository
      project.design_repository
    end

    def designs_by_filename(filenames)
      designs.current.where(filename: filenames)
    end

    private

    def update_stored_copy_state!
      # As "ready" is the initial copy state we can clear the cached value
      # rather than persist it.
      if copy_ready?
        unset_store_copy_state!
      else
        set_stored_copy_state!
      end
    end

    def copy_state_cache_key
      "DesignCollection/copy_state/issue=#{issue.id}"
    end

    def get_stored_copy_state
      Gitlab::Redis::SharedState.with do |redis|
        redis.get(copy_state_cache_key)
      end
    end

    def set_stored_copy_state!
      Gitlab::Redis::SharedState.with do |redis|
        redis.set(copy_state_cache_key, copy_state)
      end
    end

    def unset_store_copy_state!
      Gitlab::Redis::SharedState.with do |redis|
        redis.del(copy_state_cache_key)
      end
    end
  end
end
