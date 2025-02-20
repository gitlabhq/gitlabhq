# frozen_string_literal: true

namespace :gitlab do
  namespace :db do
    desc "GitLab | DB | Deduplicate CI tags"
    task deduplicate_tags: %i[environment] do
      Gitlab::Database::DeduplicateCiTags.new(
        logger: Logger.new($stdout),
        dry_run: Gitlab::Utils.to_boolean(ENV['DRY_RUN'], default: false)
      ).execute
    end
  end
end
