AssetSync.configure do |config|
  # Disable the asset_sync gem by default. If it is enabled, but not configured,
  # asset_sync will cause the build to fail.
  config.enabled =  if ENV.has_key?('ASSET_SYNC_ENABLED')
                      ENV['ASSET_SYNC_ENABLED'] == 'true'
                    else
                      false
                    end

  # Pulled from https://github.com/AssetSync/asset_sync/blob/v2.2.0/lib/asset_sync/engine.rb#L15-L40
  # This allows us to disable asset_sync by default and configure through environment variables
  # Updates to asset_sync gem should be checked
  config.fog_provider = ENV['FOG_PROVIDER'] if ENV.has_key?('FOG_PROVIDER')
  config.fog_directory = ENV['FOG_DIRECTORY'] if ENV.has_key?('FOG_DIRECTORY')
  config.fog_region = ENV['FOG_REGION'] if ENV.has_key?('FOG_REGION')

  config.aws_access_key_id = ENV['ASSETS_AWS_ACCESS_KEY_ID'] if ENV.has_key?('ASSETS_AWS_ACCESS_KEY_ID')
  config.aws_secret_access_key = ENV['ASSETS_AWS_SECRET_ACCESS_KEY'] if ENV.has_key?('ASSETS_AWS_SECRET_ACCESS_KEY')
  config.aws_reduced_redundancy = ENV['AWS_REDUCED_REDUNDANCY'] == true  if ENV.has_key?('AWS_REDUCED_REDUNDANCY')

  config.rackspace_username = ENV['RACKSPACE_USERNAME'] if ENV.has_key?('RACKSPACE_USERNAME')
  config.rackspace_api_key = ENV['RACKSPACE_API_KEY'] if ENV.has_key?('RACKSPACE_API_KEY')

  config.google_storage_access_key_id = ENV['GOOGLE_STORAGE_ACCESS_KEY_ID'] if ENV.has_key?('GOOGLE_STORAGE_ACCESS_KEY_ID')
  config.google_storage_secret_access_key = ENV['GOOGLE_STORAGE_SECRET_ACCESS_KEY'] if ENV.has_key?('GOOGLE_STORAGE_SECRET_ACCESS_KEY')

  config.existing_remote_files = ENV['ASSET_SYNC_EXISTING_REMOTE_FILES'] || "keep"

  config.gzip_compression = (ENV['ASSET_SYNC_GZIP_COMPRESSION'] == 'true') if ENV.has_key?('ASSET_SYNC_GZIP_COMPRESSION')
  config.manifest = (ENV['ASSET_SYNC_MANIFEST'] == 'true') if ENV.has_key?('ASSET_SYNC_MANIFEST')
end
