# frozen_string_literal: true

module Types
  module Packages
    class PackageStatusEnum < BaseEnum
      graphql_name 'PackageStatus'

      ::Packages::Package.statuses.keys.each do |status|
        value status.to_s.upcase, description: "Packages with a #{status} status", value: status.to_s
      end
    end
  end
end
