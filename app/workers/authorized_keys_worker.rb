# frozen_string_literal: true

class AuthorizedKeysWorker
  include ApplicationWorker

  data_consistency :sticky

  sidekiq_options retry: 3

  feature_category :source_code_management
  urgency :high
  weight 2
  idempotent!
  loggable_arguments 0

  def perform(action, *args)
    return unless Gitlab::CurrentSettings.authorized_keys_enabled?

    case action
    when 'add_key' then authorized_keys.add_key(*args)
    when 'remove_key' then authorized_keys.remove_key(*args)
    else raise "Unknown action: #{action.inspect}"
    end
  end

  private

  def authorized_keys
    @authorized_keys ||= Gitlab::AuthorizedKeys.new
  end
end
