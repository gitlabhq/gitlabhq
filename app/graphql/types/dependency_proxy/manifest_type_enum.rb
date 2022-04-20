# frozen_string_literal: true

module Types
  class DependencyProxy::ManifestTypeEnum < BaseEnum
    graphql_name 'DependencyProxyManifestStatus'

    ::DependencyProxy::Manifest.statuses.keys.each do |status|
      value status.upcase, description: "Dependency proxy manifest has a status of #{status}.", value: status
    end
  end
end
