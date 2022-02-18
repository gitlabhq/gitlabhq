# frozen_string_literal: true

module Groups
  class UpdateStatisticsService
    attr_reader :group, :statistics

    def initialize(group, statistics: [])
      @group = group
      @statistics = statistics
    end

    def execute
      unless group
        return ServiceResponse.error(message: 'Invalid group', http_status: 400)
      end

      namespace_statistics.refresh!(only: statistics.map(&:to_sym))

      ServiceResponse.success(message: 'Group statistics successfully updated.')
    end

    private

    def namespace_statistics
      @namespace_statistics ||= group.namespace_statistics || group.build_namespace_statistics
    end
  end
end
