# frozen_string_literal: true

module Provider
  module PublishContractHelper
    PROVIDER_VERSION = ENV["GIT_COMMIT"] || `git rev-parse --verify HEAD`.strip
    PROVIDER_BRANCH = ENV["GIT_BRANCH"] || `git name-rev --name-only HEAD`.strip
    PUBLISH_FLAG = true

    def self.publish_contract_setup
      ->(app_version, app_version_branch, publish_verification_results) {
        app_version.call(PROVIDER_VERSION)
        app_version_branch.call(PROVIDER_BRANCH)
        publish_verification_results.call(PUBLISH_FLAG)
      }
    end
  end
end
