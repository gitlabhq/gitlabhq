# frozen_string_literal: true

module Resolvers
  class DataTransferResolver < BaseResolver
    argument :from, Types::DateType,
      description: 'Retain egress data for 1 year. Current month will increase dynamically as egress occurs.',
      required: false
    argument :to, Types::DateType,
      description: 'End date for the data.',
      required: false

    type ::Types::DataTransfer::BaseType, null: false

    def self.source
      raise NotImplementedError
    end

    def self.project
      Class.new(self) do
        type Types::DataTransfer::ProjectDataTransferType, null: false

        def self.source
          "Project"
        end
      end
    end

    def self.group
      Class.new(self) do
        type Types::DataTransfer::GroupDataTransferType, null: false

        def self.source
          "Group"
        end
      end
    end

    def resolve(**_args)
      return unless Feature.enabled?(:data_transfer_monitoring)

      # TODO: This is mock data as this feature is in development
      # Follow this epic for recent progress: https://gitlab.com/groups/gitlab-org/-/epics/9330
      start_date = Date.new(2023, 0o1, 0o1)
      date_for_index = ->(i) { (start_date + i.months).strftime('%Y-%m-%d') }

      nodes = 0.upto(11).map do |i|
        {
          date: date_for_index.call(i),
          repository_egress: rand(70000..550000),
          artifacts_egress: rand(70000..550000),
          packages_egress: rand(70000..550000),
          registry_egress: rand(70000..550000)
        }
      end

      { egress_nodes: nodes }
    end
  end
end
