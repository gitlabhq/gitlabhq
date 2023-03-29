# frozen_string_literal: true

module DataTransfer
  class GroupDataTransferFinder
    def initialize(group:, from:, to:, user:)
      @group = group
      @from = from
      @to = to
      @user = user
    end

    def execute
      return ::Projects::DataTransfer.none unless Ability.allowed?(user, :read_usage_quotas, group)

      ::Projects::DataTransfer
        .with_namespace_between_dates(group, from, to)
        .select('SUM(repository_egress
                      + artifacts_egress
                      + packages_egress
                      + registry_egress
                      ) as total_egress,
        SUM(repository_egress) as repository_egress,
        SUM(artifacts_egress) as artifacts_egress,
        SUM(packages_egress) as packages_egress,
        SUM(registry_egress) as registry_egress,
        date,
        namespace_id')
    end

    private

    attr_reader :group, :from, :to, :user
  end
end
