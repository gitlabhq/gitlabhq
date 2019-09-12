# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class AddGitlabInstanceAdministrationProject
      def perform
        Rails.logger.info("Creating Gitlab instance administration project") # rubocop:disable Gitlab/RailsLogger

        Gitlab::DatabaseImporters::SelfMonitoring::Project::CreateService.new.execute!
      end
    end
  end
end
