module Ci
  # Currently this model is not persisted in the database, but derived from a
  # pipelines jobs. We might, but at the same time might not, persist this model
  # in the database later
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
        Gitlab::Ci::Status::Group::Factory.new(self, current_user).fabricate!
      end
    end

    private

    def commit_statuses
      @commit_statuses ||= CommitStatus.where(id: jobs.map(&:id))
    end
  end
end
