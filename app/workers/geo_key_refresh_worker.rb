class GeoKeyRefreshWorker
  include Sidekiq::Worker
  include GeoDynamicBackoff

  sidekiq_options queue: :default

  def perform(key_id, key, action)
    action = action.to_sym

    case action
    when :create
      # ActiveRecord::RecordNotFound when not found (so job will retry)
      key = Key.find(key_id)
      key.add_to_shell
    when :delete
      # we are physically removing the key after model is removed
      # so we must reconstruct ids to schedule removal
      key = Key.new(id: key_id, key: key)
      key.remove_from_shell
    else
      fail "Invalid action: #{action}"
    end
  end
end
