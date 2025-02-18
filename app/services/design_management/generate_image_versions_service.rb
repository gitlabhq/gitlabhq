# frozen_string_literal: true

module DesignManagement
  # This service generates smaller image versions for `DesignManagement::Design`
  # records within a given `DesignManagement::Version`.
  class GenerateImageVersionsService < DesignService
    # We limit processing to only designs with file sizes that don't
    # exceed `MAX_DESIGN_SIZE`.
    #
    # Note, we may be able to remove checking this limit, if when we come to
    # implement a file size limit for designs, there are no designs that
    # exceed 40MB on GitLab.com
    #
    # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22860#note_281780387
    MAX_DESIGN_SIZE = 40.megabytes.freeze

    def initialize(version)
      super(version.project, version.author, issue: version.issue)

      @version = version
    end

    def execute
      # rubocop: disable CodeReuse/ActiveRecord
      version.actions.includes(:design).find_each do |action|
        generate_image(action)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      success(version: version)
    end

    private

    attr_reader :version

    def generate_image(action)
      raw_file = get_raw_file(action)

      unless raw_file
        log_error("No design file found for Action: #{action.id}")
        return
      end

      # Skip attempting to process images that would be rejected by CarrierWave.
      return unless DesignManagement::DesignV432x230Uploader::MIME_TYPE_ALLOWLIST.include?(raw_file.content_type)

      # Store and process the file
      action.image_v432x230.store!(raw_file)
      action.save!
    rescue CarrierWave::IntegrityError => e
      Gitlab::ErrorTracking.log_exception(e, project_id: project.id, design_id: action.design_id, version_id: action.version_id)
      log_error(e.message)
    rescue CarrierWave::UploadError => e
      Gitlab::ErrorTracking.track_exception(e, project_id: project.id, design_id: action.design_id, version_id: action.version_id)
      log_error(e.message)
    end

    # Returns the `CarrierWave::SanitizedFile` of the original design file
    def get_raw_file(action)
      raw_files_by_path[action.design.full_path]
    end

    # Returns the `Carrierwave:SanitizedFile` instances for all of the original
    # design files, mapping to { design.filename => `Carrierwave::SanitizedFile` }.
    #
    # As design files are stored in Git LFS, the only way to retrieve their original
    # files is to first fetch the LFS pointer file data from the Git design repository.
    # The LFS pointer file data contains an "OID" that lets us retrieve `LfsObject`
    # records, which have an Uploader (`LfsObjectUploader`) for the original design file.
    def raw_files_by_path
      @raw_files_by_path ||= LfsObject.for_oids(blobs_by_oid.keys).each_with_object({}) do |lfs_object, h|
        blob = blobs_by_oid[lfs_object.oid]
        file = lfs_object.file.file
        # The `CarrierWave::SanitizedFile` is loaded without knowing the `content_type`
        # of the file, due to the file not having an extension.
        #
        # Set the content_type from the `Blob`.
        file.content_type = blob.content_type
        h[blob.path] = file
      end
    end

    # Returns the `Blob`s that correspond to the design files in the repository.
    #
    # All design `Blob`s are LFS Pointer files, and are therefore small amounts
    # of data to load.
    #
    # `Blob`s whose size are above a certain threshold: `MAX_DESIGN_SIZE`
    # are filtered out.
    def blobs_by_oid
      @blobs ||= begin
        items = version.designs.map { |design| [version.sha, design.full_path] }
        blobs = repository.blobs_at(items)
        blobs.reject! { |blob| blob.lfs_size > MAX_DESIGN_SIZE }
        blobs.index_by(&:lfs_oid)
      end
    end
  end
end
