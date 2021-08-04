# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Queue
      extend ActiveSupport::Concern

      included do
        queue_namespace :github_importer
        feature_category :importers

        # If a job produces an error it may block a stage from advancing
        # forever. To prevent this from happening we prevent jobs from going to
        # the dead queue. This does mean some resources may not be imported, but
        # this is better than a project being stuck in the "import" state
        # forever.
        sidekiq_options dead: false, retry: 5

        sidekiq_retries_exhausted do |msg, e|
          Logger.error(
            event: :github_importer_exhausted,
            message: msg['error_message'],
            class: msg['class'],
            args: msg['args'],
            exception_message: e.message,
            exception_backtrace: e.backtrace
          )
        end
      end
    end
  end
end
