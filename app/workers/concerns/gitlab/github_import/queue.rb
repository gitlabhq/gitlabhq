module Gitlab
  module GithubImport
    module Queue
      extend ActiveSupport::Concern

      included do
        queue_namespace :github_importer

        # If a job produces an error it may block a stage from advancing
        # forever. To prevent this from happening we prevent jobs from going to
        # the dead queue. This does mean some resources may not be imported, but
        # this is better than a project being stuck in the "import" state
        # forever.
        sidekiq_options dead: false, retry: 5
      end
    end
  end
end
