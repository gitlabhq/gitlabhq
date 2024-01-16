# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Queue
      extend ActiveSupport::Concern

      included do
        queue_namespace :github_importer
        feature_category :importers
        sidekiq_options dead: false
      end
    end
  end
end
