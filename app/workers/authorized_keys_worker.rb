# frozen_string_literal: true

class AuthorizedKeysWorker
  include ApplicationWorker

  PERMITTED_ACTIONS = [:add_key, :remove_key].freeze

  feature_category :source_code_management
  urgency :high
  weight 2
  idempotent!

  def perform(action, *args)
    return unless Gitlab::CurrentSettings.authorized_keys_enabled?

    case action
    when :add_key
      authorized_keys.add_key(*args)
    when :remove_key
      authorized_keys.remove_key(*args)
    end
  end

  private

  def authorized_keys
    @authorized_keys ||= Gitlab::AuthorizedKeys.new
  end
end
