# frozen_string_literal: true

require_relative '../../tooling/danger/post_deployment_migration'

module Danger
  class PostDeploymentMigration < ::Danger::Plugin
    include Tooling::Danger::PostDeploymentMigration
  end
end
