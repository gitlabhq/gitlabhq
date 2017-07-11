# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UpdateAuthorizedKeysFile < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  class ApplicationSetting < ActiveRecord::Base
    self.table_name = 'application_settings'
  end

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # We started deploying 9.3.0 to GitLab.com at 2017-06-22 17:24 UTC, and the
  # package was pushed some time before that. Some buffer room is included here.
  DATETIME_9_3_0_RELEASED = DateTime.parse('2017-06-22T00:00:00+00:00')

  def up
    if authorized_keys_file_in_use_and_stale?
      say 'The authorized_keys file is in use, and may be stale. Now bringing it up-to-date in the background...'

      # Update nil authorized_keys_enabled to true to ensure that Gitlab::Shell
      # key methods work properly for workers running 9.3.0 during the
      # migration. If the setting remained nil, the workers would not edit the
      # file.
      update_nil_setting_to_true

      update_authorized_keys_file_since(DATETIME_9_3_0_RELEASED)
    else
      say 'The authorized_keys file does not need to be updated. Skipping...'
    end
  end

  def down
    # Do nothing
  end

  def authorized_keys_file_in_use_and_stale?
    return false unless ran_broken_migration?

    @uncached_application_setting = ApplicationSetting.last

    # If there is no ApplicationSetting record in the DB, then the instance was
    # never in a state where `authorized_keys_enabled` field was `nil`. So the
    # file is not stale.
    return false unless @uncached_application_setting

    if @uncached_application_setting.authorized_keys_enabled == false # not falsey!
      # If authorized_keys_enabled is explicitly false, then the file is not in
      # use, so it doesn't need to be fixed. I.e. GitLab.com.
      #
      # Unfortunately it is possible some users may have saved Application
      # Settings without realizing the new option existed, and since it
      # mistakenly defaulted to unchecked, now it is explicitly false. These
      # users need this warning.
      say false_negative_warning
      return false
    end

    # If authorized_keys_enabled is true or nil, then we need to rebuild the
    # file in case it is stale.
    true
  end

  def ran_broken_migration?
    # If the column is already fixed, then the migration wasn't run before now.
    default_value = Gitlab::Database.postgresql? ? 'true' : '1'

    column_has_no_default = !column_exists?(:application_settings, :authorized_keys_enabled, :boolean, default: default_value, null: false)
    say "This GitLab installation was #{'never ' unless column_has_no_default}upgraded to exactly version 9.3.0."

    column_has_no_default
  end

  def false_negative_warning
    <<-MSG.strip_heredoc
      WARNING

      If you did not intentionally disable the "Write to authorized_keys file"
      option in Application Settings as outlined in the Speed up SSH
      documentation,

      https://docs.gitlab.com/ee/administration/operations/speed_up_ssh.html

      then the authorized_keys file may be out-of-date, affecting SSH
      operations.

      If you are affected, please check the "Write to authorized_keys file"
      checkbox, and Save. Then rebuild the authorized_keys file as shown here:

      https://docs.gitlab.com/ee/administration/raketasks/maintenance.html#rebuild-authorized_keys-file

      For more information, see the issue:

      https://gitlab.com/gitlab-org/gitlab-ee/issues/2738
    MSG
  end

  def update_nil_setting_to_true
    @uncached_application_setting.update_attribute(:authorized_keys_enabled, true)
  end

  def update_authorized_keys_file_since(cutoff_datetime)
    job = [['UpdateAuthorizedKeysFileSince', [cutoff_datetime]]]
    BackgroundMigrationWorker.perform_bulk(job)
  end
end
