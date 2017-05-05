module Ci
  # Currently this model is not persisted in the database, but derived from a
  # pipelines jobs. We might, but at the same time might not, persist this model
  # in the database later
  class Group
    include StaticModel

    attr_reader :stage, :name, :statuses

    def initialize(stage, name:, statuses:)
      @stage = stage
      @name = name
      @statuses = statuses
    end

    def status
      @status ||= commit_statuses.status
    end

    def detailed_status(current_user)
      if size == 1
        statuses[0].detailed_status(current_user)
      else
        Gitlab::Ci::Status::Group::Factory.new(self, current_user).fabricate!
      end
    end

    def size
      statuses.size
    end

    private

    def commit_statuses
      @commit_statuses ||= CommitStatus.where(id: statuses.map(&:id))
    end
  end
end
