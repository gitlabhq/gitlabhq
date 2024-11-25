# frozen_string_literal: true

# rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- We want to set sequence limits only on Gitlab instances
namespace :gitlab do
  namespace :db do
    desc 'Alters sequence limits for cell specific tables'
    task :alter_cell_sequences_range, [:minval, :maxval] => :environment do |_t, args|
      next unless Gitlab.com_except_jh? || Gitlab.dev_or_test_env?

      # This is a safety check to ensure this rake does not alters the sequences for the Legacy Cell
      next if Gitlab.config.skip_sequence_alteration?

      Gitlab::Database::EachDatabase.each_connection do |connection, _database_name|
        Gitlab::Database::AlterCellSequencesRange.new(args.minval&.to_i, args.maxval&.to_i, connection).execute
      end
    end
  end
end
# rubocop:enable Gitlab/AvoidGitlabInstanceChecks
