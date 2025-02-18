# frozen_string_literal: true

namespace :ci do
  namespace :job_tokens do
    namespace :allowlist do
      desc "CI | Job Tokens | Allowlist | Autopopulate allowlist from authorization log entries"
      task autopopulate_and_enforce: :environment do
        only_ids = ENV['ONLY_PROJECT_IDS']
        exclude_ids = ENV['EXCLUDE_PROJECT_IDS']
        preview = ENV['PREVIEW']

        require_relative '../../../app/models/ci/job_token/allowlist_migration_task'

        task = ::Ci::JobToken::AllowlistMigrationTask.new(only_ids: only_ids,
          exclude_ids: exclude_ids,
          preview: preview,
          user: ::Users::Internal.admin_bot)

        task.execute
      end
    end
  end
end
