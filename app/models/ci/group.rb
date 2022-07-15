# frozen_string_literal: true

module Ci
  ##
  # This domain model is a representation of a group of jobs that are related
  # to each other, like `rspec 0 1`, `rspec 0 2`.
  #
  # It is not persisted in the database.
  #
  class Group
    include StaticModel
    include Gitlab::Utils::StrongMemoize
    include GlobalID::Identification

    attr_reader :project, :stage, :name, :jobs

    delegate :size, to: :jobs

    def initialize(project, stage, name:, jobs:)
      @project = project
      @stage = stage
      @name = name
      @jobs = jobs
    end

    def id
      "#{stage.id}-#{name}"
    end

    def ==(other)
      other.present? && other.is_a?(self.class) &&
        project == other.project &&
        stage == other.stage &&
        name == other.name
    end

    def status
      strong_memoize(:status) do
        status_struct.status
      end
    end

    def success?
      status.to_s == 'success'
    end

    def has_warnings?
      status_struct.warnings?
    end

    def status_struct
      strong_memoize(:status_struct) do
        Gitlab::Ci::Status::Composite.new(@jobs)
      end
    end

    def detailed_status(current_user)
      if jobs.one?
        jobs.first.detailed_status(current_user)
      else
        Gitlab::Ci::Status::Group::Factory
          .new(self, current_user).fabricate!
      end
    end

    # Construct a grouping of statuses for this stage.
    # We allow the caller to pass in statuses for efficiency (avoiding N+1
    # queries).
    def self.fabricate(project, stage, statuses = nil)
      statuses ||= stage.latest_statuses

      statuses
        .sort_by(&:sortable_name).group_by(&:group_name)
        .map do |group_name, grouped_statuses|
          self.new(project, stage, name: group_name, jobs: grouped_statuses)
        end
    end
  end
end
