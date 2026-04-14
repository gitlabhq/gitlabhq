# frozen_string_literal: true

# rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- We want to set sequence limits only on Gitlab instances
namespace :gitlab do
  namespace :db do
    desc 'Alters max value for all sequences on the legacy cell'
    task :alter_legacy_cell_sequences_max_value, [:maxval] => :environment do |_t, args|
      next unless Gitlab.com_except_jh? || Gitlab.dev_or_test_env?

      next if Gitlab.config.cell.database.skip_sequence_alteration

      sequence_names = ENV['SEQUENCE_NAMES']
      sequence_names = sequence_names&.split(',')&.map(&:strip)&.reject(&:blank?).presence
      skip_trigger_install = Gitlab::Utils.to_boolean(ENV['SKIP_SEQUENCE_TRIGGER_INSTALL'], default: false)

      Gitlab::Database::EachDatabase.each_connection do |connection, _database_name|
        Gitlab::Database::AlterLegacyCellSequencesMaxValue.new(
          args.maxval&.to_i, connection, sequence_names: sequence_names,
          skip_trigger_install: skip_trigger_install
        ).execute
      end
    end

    desc 'Rolls back max value alteration for all sequences on the legacy cell'
    # Intentionally does not check skip_sequence_alteration: rollback must always be
    # available to restore sequences to their default max value, even when the forward
    # task is disabled via configuration.
    task rollback_alter_legacy_cell_sequences_max_value: :environment do
      next unless Gitlab.com_except_jh? || Gitlab.dev_or_test_env?

      sequence_names = ENV['SEQUENCE_NAMES']
      sequence_names = sequence_names&.split(',')&.map(&:strip)&.reject(&:blank?).presence

      Gitlab::Database::EachDatabase.each_connection do |connection, _database_name|
        maxval = Gitlab::Database::AlterLegacyCellSequencesMaxValue::DEFAULT_MAX_VALUE

        Gitlab::Database::AlterLegacyCellSequencesMaxValue.new(
          maxval, connection, sequence_names: sequence_names
        ).rollback
      end
    end
  end
end
# rubocop:enable Gitlab/AvoidGitlabInstanceChecks
