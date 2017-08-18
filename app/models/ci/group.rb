module Ci
  ##
  # This domain model is a representation of a group of jobs that are related
  # to each other, like `rspec 0 1`, `rspec 0 2`.
  #
  # It is not persisted in the database.
  #
  class Group
    include StaticModel

    attr_reader :stage, :name, :jobs

    delegate :size, to: :jobs

    def initialize(stage, name:, jobs:)
      @stage = stage
      @name = name
      @jobs = jobs
    end

    def status
      @status ||= commit_statuses.status
    end

    def detailed_status(current_user)
      if jobs.one?
        jobs.first.detailed_status(current_user)
      else
        Gitlab::Ci::Status::Group::Factory
          .new(self, current_user).fabricate!
      end
    end

    private

    def commit_statuses
      @commit_statuses ||= CommitStatus.where(id: jobs.map(&:id))
    end
  end
end
