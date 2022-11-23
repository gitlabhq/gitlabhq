# frozen_string_literal: true

module Provider
  module PublishContractHelper
    PROVIDER_VERSION = ENV["GIT_COMMIT"] || `git rev-parse --verify HEAD`.strip
    PROVIDER_BRANCH = ENV["GIT_BRANCH"] || `git name-rev --name-only HEAD`.strip
    PUBLISH_FLAG = true

    def publish_contract_setup
      -> {
        app_version PROVIDER_VERSION
        app_version_branch PROVIDER_BRANCH
        publish_verification_results PUBLISH_FLAG
      }
    end
  end
end
