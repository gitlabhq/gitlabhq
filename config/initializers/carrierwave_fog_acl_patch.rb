# frozen_string_literal: true

require "carrierwave/storage/fog"

# Consolidated CarrierWave fog patch backporting several upstream fixes for
# CarrierWave 1.3.4. Remove this file once CarrierWave is upgraded to a
# version that includes all of the following PRs.
#
# - https://github.com/carrierwaveuploader/carrierwave/pull/2811
#   fog_acl: when set to false, omits :public from fog file/directory creation
#   to prevent x-amz-acl headers being sent to S3 buckets with ACLs disabled
#   (Bucket Owner Enforced). See https://gitlab.com/gitlab-org/gitlab/-/issues/396349
#
# - https://github.com/carrierwaveuploader/carrierwave/pull/2504
#   Sends AWS S3 encryption headers (fog_attributes) when copying objects.
#
# - https://github.com/carrierwaveuploader/carrierwave/pull/2375
#   Azure support in authenticated_url.
#
# - https://github.com/carrierwaveuploader/carrierwave/pull/2397
#   Custom expire_at support in authenticated_url.

CarrierWave::Uploader::Base.add_config :fog_acl

# rubocop:disable Gitlab/ModuleWithInstanceVariables -- prepend modules for
# CarrierWave monkey-patching legitimately need access to the instance variables
# of the classes they are prepended into.
module CarrierWaveFogAclPatch
  def fog_public_attrs
    uploader.fog_acl.nil? ? { public: uploader.fog_public } : {}
  end

  def clean_cache!(seconds)
    # rubocop:disable Rails/FindEach -- fog file collections are not ActiveRecord relations
    connection.directories.new(
      { key: uploader.fog_directory }.merge(fog_public_attrs)
    ).files.all(prefix: uploader.cache_dir).each do |file|
      time = file.key.scan(/(\d+)-\d+-\d+-\d+/).first.map(&:to_i)
      time = Time.at(*time)
      file.destroy if time < (Time.now.utc - seconds)
    end
    # rubocop:enable Rails/FindEach
  end
end

module CarrierWaveFogFileAclPatch
  def fog_public_attrs
    @uploader.fog_acl.nil? ? { public: @uploader.fog_public } : {}
  end

  def store(new_file)
    if new_file.is_a?(self.class)
      new_file.copy_to(path)
    else
      fog_file = new_file.to_file
      @content_type ||= new_file.content_type
      @file = directory.files.create(
        {
          body: fog_file || new_file.read,
          content_type: @content_type,
          key: path
        }.merge(fog_public_attrs).merge(@uploader.fog_attributes)
      )
      fog_file.close if fog_file && !fog_file.closed?
    end

    true
  end

  def copy_to(new_path)
    # fog-aws supports multithreaded multipart copies for large files.
    # See https://github.com/fog/fog-aws/pull/579
    # rubocop:disable Gitlab/FeatureFlagWithoutActor -- ops flags apply globally and do not require an actor
    if ::Feature.enabled?(:s3_multithreaded_uploads, type: :ops) && fog_provider == 'AWS'
      # rubocop:enable Gitlab/FeatureFlagWithoutActor
      file.concurrency = 10
      file.multipart_chunk_size = 10.megabytes
      file.copy(@uploader.fog_directory, new_path, copy_to_options)
    else
      connection.copy_object(@uploader.fog_directory, file.key, @uploader.fog_directory, new_path, copy_to_options)
    end

    CarrierWave::Storage::Fog::File.new(@uploader, @base, new_path)
  end

  def copy_to_options
    acl_header.merge(@uploader.fog_attributes)
  end

  def acl_header
    fog_acl = @uploader.fog_acl
    return {} if fog_acl == false

    case fog_provider
    when 'AWS'
      acl_value = fog_acl || (@uploader.fog_public ? 'public-read' : 'private')
      { 'x-amz-acl' => acl_value }
    when 'Google'
      # Only send a Google ACL header when fog_acl is an explicit string.
      # When fog_acl is nil, preserve the original CarrierWave 1.3.4 behaviour
      # which returns {} for all non-AWS providers.
      fog_acl ? { destination_predefined_acl: fog_acl } : {}
    else
      {}
    end
  end

  def authenticated_url(options = {})
    if %w[AWS Google AzureRM].include?(@uploader.fog_credentials[:provider]) # rubocop:disable Style/GuardClause -- preserve upstream code structure
      # avoid a get by using local references
      local_directory = connection.directories.new(key: @uploader.fog_directory)
      local_file = local_directory.files.new(key: path)
      expire_at = options[:expire_at] || (::Fog::Time.now + @uploader.fog_authenticated_url_expiration)
      case @uploader.fog_credentials[:provider]
      when 'AWS', 'Google', 'AzureRM'
        local_file.url(expire_at, options)
      else
        local_file.url(expire_at)
      end
    end
  end

  private

  def directory
    @directory ||= connection.directories.new(
      { key: @uploader.fog_directory }.merge(fog_public_attrs)
    )
  end
end
# rubocop:enable Gitlab/ModuleWithInstanceVariables

CarrierWave::Storage::Fog.prepend(CarrierWaveFogAclPatch)
CarrierWave::Storage::Fog::File.prepend(CarrierWaveFogFileAclPatch)
