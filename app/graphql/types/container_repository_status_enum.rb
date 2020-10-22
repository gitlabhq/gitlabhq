# frozen_string_literal: true

module Types
  class ContainerRepositoryStatusEnum < BaseEnum
    graphql_name 'ContainerRepositoryStatus'
    description 'Status of a container repository'

    ::ContainerRepository.statuses.keys.each do |status|
      value status.upcase, value: status, description: "#{status.titleize} status."
    end
  end
end
