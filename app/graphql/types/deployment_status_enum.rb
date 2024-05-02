# frozen_string_literal: true

module Types
  class DeploymentStatusEnum < BaseEnum
    graphql_name 'DeploymentStatus'
    description 'All deployment statuses.'

    ::Deployment.statuses.each_key do |status|
      value status.upcase,
        description: "A deployment that is #{status.tr('_', ' ')}.",
        value: status
    end
  end
end
