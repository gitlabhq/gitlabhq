# frozen_string_literal: true

class ChangeDefaultValueOfThrottleProtectedPaths < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column_default :application_settings, :throttle_protected_paths_enabled, false

    # Because we already set the value to true in the previous
    # migration, this feature was switched on inadvertently in GitLab
    # 12.4. This migration toggles it back off to ensure we don't
    # inadvertently block legitimate users. The admin will have to
    # re-enable it in the application settings.
    unless omnibus_protected_paths_present?
      execute "UPDATE application_settings SET throttle_protected_paths_enabled = #{false_value}"
    end
  end

  def down
    change_column_default :application_settings, :throttle_protected_paths_enabled, true

    execute "UPDATE application_settings SET throttle_protected_paths_enabled = #{true_value}"
  end

  private

  def omnibus_protected_paths_present?
    Rack::Attack.throttles.key?('protected paths')
  rescue e
    say "Error while checking if Omnibus protected paths were already enabled: #{e.message}"
    say 'Continuing. Protected paths will remain enabled.'

    # Return true so we don't take a risk
    true
  end
end
