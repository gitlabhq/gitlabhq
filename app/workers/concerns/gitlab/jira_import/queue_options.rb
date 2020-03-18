# frozen_string_literal: true

module Gitlab
  module JiraImport
    module QueueOptions
      extend ActiveSupport::Concern

      included do
        queue_namespace :jira_importer
        feature_category :importers

        sidekiq_options retry: 5
      end
    end
  end
end
