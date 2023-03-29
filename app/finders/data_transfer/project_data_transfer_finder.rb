# frozen_string_literal: true

module DataTransfer
  class ProjectDataTransferFinder
    def initialize(project:, from:, to:, user:)
      @project = project
      @from = from
      @to = to
      @user = user
    end

    def execute
      return ::Projects::DataTransfer.none unless Ability.allowed?(user, :read_usage_quotas, project)

      ::Projects::DataTransfer
        .with_project_between_dates(project, from, to)
        .select(:project_id, :date, :repository_egress, :artifacts_egress, :packages_egress, :registry_egress,
          "repository_egress + artifacts_egress + packages_egress + registry_egress as total_egress")
    end

    private

    attr_reader :project, :from, :to, :user
  end
end
