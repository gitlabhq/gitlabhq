# Set default values for object_store settings
class ObjectStoreSettings
  def self.parse(object_store)
    object_store ||= Settingslogic.new({})
    object_store['enabled'] = false if object_store['enabled'].nil?
    object_store['remote_directory'] ||= nil
    object_store['direct_upload'] = false if object_store['direct_upload'].nil?
    object_store['background_upload'] = true if object_store['background_upload'].nil?
    object_store['proxy_download'] = false if object_store['proxy_download'].nil?

    # Convert upload connection settings to use string keys, to make Fog happy
    object_store['connection']&.deep_stringify_keys!
    object_store
  end
end
