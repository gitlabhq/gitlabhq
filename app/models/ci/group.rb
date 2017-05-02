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

    def detailed_status(current_user)
      Gitlab::Ci::Status::Group::Factory
        .new(CommitStatus.where(id: statuses.map(&:id)), current_user)
        .fabricate!
    end

    def size
      statuses.size
    end
  end
end
