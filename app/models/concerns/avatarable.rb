module Avatarable
  extend ActiveSupport::Concern

  included do
    prepend ShadowMethods
    include ObjectStorage::BackgroundMove
    include Gitlab::Utils::StrongMemoize

    validate :avatar_type, if: ->(user) { user.avatar.present? && user.avatar_changed? }
    validates :avatar, file_size: { maximum: 200.kilobytes.to_i }

    mount_uploader :avatar, AvatarUploader

    after_initialize :add_avatar_to_batch
  end

  module ShadowMethods
    def avatar_url(**args)
      # We use avatar_path instead of overriding avatar_url because of carrierwave.
      # See https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/11001/diffs#note_28659864

      avatar_path(only_path: args.fetch(:only_path, true)) || super
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

  def avatar_type
    unless self.avatar.image?
      errors.add :avatar, "file format is not supported. Please try one of the following supported formats: #{AvatarUploader::IMAGE_EXT.join(', ')}"
    end
  end

  def avatar_path(only_path: true)
    return unless self[:avatar].present?

    asset_host = ActionController::Base.asset_host
    use_asset_host = asset_host.present?
    use_authentication = respond_to?(:public?) && !public?

    # Avatars for private and internal groups and projects require authentication to be viewed,
    # which means they can only be served by Rails, on the regular GitLab host.
    # If an asset host is configured, we need to return the fully qualified URL
    # instead of only the avatar path, so that Rails doesn't prefix it with the asset host.
    if use_asset_host && use_authentication
      use_asset_host = false
      only_path = false
    end

    url_base = ""
    if use_asset_host
      url_base << asset_host unless only_path
    else
      url_base << gitlab_config.base_url unless only_path
      url_base << gitlab_config.relative_url_root
    end

    url_base + avatar.local_url
  end

  # Path that is persisted in the tracking Upload model. Used to fetch the
  # upload from the model.
  def upload_paths(identifier)
    avatar_mounter.blank_uploader.store_dirs.map { |store, path| File.join(path, identifier) }
  end

  private

  def retrieve_upload_from_batch(identifier)
    BatchLoader.for(identifier: identifier, model: self).batch(key: self.class) do |upload_params, loader, args|
      model_class = args[:key]
      paths = upload_params.flat_map do |params|
        params[:model].upload_paths(params[:identifier])
      end

      Upload.where(uploader: AvatarUploader, path: paths).find_each do |upload|
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
end
