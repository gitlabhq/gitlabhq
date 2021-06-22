# frozen_string_literal: true

module Avatarable
  extend ActiveSupport::Concern

  USER_AVATAR_SIZES = [16, 20, 23, 24, 26, 32, 36, 38, 40, 48, 60, 64, 90, 96, 120, 160].freeze
  PROJECT_AVATAR_SIZES = [15, 40, 48, 64, 88].freeze
  GROUP_AVATAR_SIZES = [15, 37, 38, 39, 40, 64, 96].freeze

  ALLOWED_IMAGE_SCALER_WIDTHS = (USER_AVATAR_SIZES | PROJECT_AVATAR_SIZES | GROUP_AVATAR_SIZES).freeze

  # This value must not be bigger than then: https://gitlab.com/gitlab-org/gitlab/-/blob/master/workhorse/config.toml.example#L20
  #
  # https://docs.gitlab.com/ee/development/image_scaling.html
  MAXIMUM_FILE_SIZE = 200.kilobytes.to_i

  included do
    prepend ShadowMethods
    include ObjectStorage::BackgroundMove
    include Gitlab::Utils::StrongMemoize

    validate :avatar_type, if: ->(user) { user.avatar.present? && user.avatar_changed? }
    validates :avatar, file_size: { maximum: MAXIMUM_FILE_SIZE }, if: :avatar_changed?

    mount_uploader :avatar, AvatarUploader

    after_initialize :add_avatar_to_batch
    after_commit :clear_avatar_caches
  end

  module ShadowMethods
    def avatar_url(**args)
      # We use avatar_path instead of overriding avatar_url because of carrierwave.
      # See https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/11001/diffs#note_28659864

      avatar_path(only_path: args.fetch(:only_path, true), size: args[:size]) || super
    end

    def retrieve_upload(identifier, paths)
      upload = retrieve_upload_from_batch(identifier)

      # This fallback is needed when deleting an upload, because we may have
      # already been removed from the DB. We have to check an explicit `#nil?`
      # because it's a BatchLoader instance.
      upload = super if upload.nil?

      upload
    end
  end

  class_methods do
    def bot_avatar(image:)
      Rails.root.join('lib', 'assets', 'images', 'bot_avatars', image).open
    end
  end

  def avatar_type
    unless self.avatar.image?
      errors.add :avatar, "file format is not supported. Please try one of the following supported formats: #{AvatarUploader::SAFE_IMAGE_EXT.join(', ')}"
    end
  end

  def avatar_path(only_path: true, size: nil)
    unless self.try(:id)
      return uncached_avatar_path(only_path: only_path, size: size)
    end

    # Cache this avatar path only within the request because avatars in
    # object storage may be generated with time-limited, signed URLs.
    key = "#{self.class.name}:#{self.id}:#{only_path}:#{size}"
    Gitlab::SafeRequestStore[key] ||= uncached_avatar_path(only_path: only_path, size: size)
  end

  def uncached_avatar_path(only_path: true, size: nil)
    return unless self.try(:avatar).present?

    asset_host = ActionController::Base.asset_host
    use_asset_host = asset_host.present?
    use_authentication = respond_to?(:public?) && !public?
    query_params = size&.nonzero? ? "?width=#{size}" : ""

    # Avatars for private and internal groups and projects require authentication to be viewed,
    # which means they can only be served by Rails, on the regular GitLab host.
    # If an asset host is configured, we need to return the fully qualified URL
    # instead of only the avatar path, so that Rails doesn't prefix it with the asset host.
    if use_asset_host && use_authentication
      use_asset_host = false
      only_path = false
    end

    url_base = []

    if use_asset_host
      url_base << asset_host unless only_path
    else
      url_base << gitlab_config.base_url unless only_path
      url_base << gitlab_config.relative_url_root
    end

    url_base.join + avatar.local_url + query_params
  end

  # Path that is persisted in the tracking Upload model. Used to fetch the
  # upload from the model.
  def upload_paths(identifier)
    avatar_mounter.blank_uploader.store_dirs.map { |store, path| File.join(path, identifier) }
  end

  private

  def retrieve_upload_from_batch(identifier)
    BatchLoader.for(identifier: identifier, model: self)
               .batch(key: self.class, cache: true, replace_methods: false) do |upload_params, loader, args|
      model_class = args[:key]
      paths = upload_params.flat_map do |params|
        params[:model].upload_paths(params[:identifier])
      end

      Upload.where(uploader: AvatarUploader.name, path: paths).find_each do |upload|
        model = model_class.instantiate('id' => upload.model_id)

        loader.call({ model: model, identifier: File.basename(upload.path) }, upload)
      end
    end
  end

  def add_avatar_to_batch
    return unless avatar_mounter

    avatar_mounter.read_identifiers.each { |identifier| retrieve_upload_from_batch(identifier) }
  end

  def avatar_mounter
    strong_memoize(:avatar_mounter) { _mounter(:avatar) }
  end

  def clear_avatar_caches
    return unless respond_to?(:verified_emails) && verified_emails.any? && avatar_changed?

    Gitlab::AvatarCache.delete_by_email(*verified_emails)
  end
end
