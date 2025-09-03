# frozen_string_literal: true

module SupplyChain
  class ArtifactsReader
    MAX_FILES_IN_BUNDLE = 1000
    MAX_SIZE = Gitlab::CurrentSettings.current_application_settings.max_artifacts_content_include_size

    Error = Class.new(StandardError)
    BundleTooLarge = Class.new(Error)
    NoArtifacts = Class.new(Error)
    ArtifactTooLarge = Class.new(Error)
    DiskFull = Class.new(Error)
    TooManyFiles = Class.new(Error)

    def initialize(build)
      @build = build

      raise Error, "Job doesn't exist" unless @build
      raise NoArtifacts, "#{build_id} does not have artifacts" unless @build.artifacts?
      raise Error, "#{build_id} has missing metadata and cannot be extracted" unless @build.artifacts_metadata?

      @metadata = build.artifacts_metadata_entry('', recursive: true)
      raise Error, "#{build_id} has invalid metadata" unless @metadata

      validate_bundle!
    end

    def files
      artifacts = artifacts_in_metadata
      @build.artifacts_file.use_open_file(unlink_early: false) do |tmp_open_file|
        zip_file_path = tmp_open_file.file_path

        Zip::File.open(zip_file_path) do |zip_file| # rubocop:disable Performance/Rubyzip -- General purpose flag Bit 3 is set so not possible to get proper info from local header
          artifacts.each do |artifact|
            entry = zip_file.get_entry(artifact)

            yield entry.name, entry.get_input_stream
          end
        end
      end
    rescue Errno::EDQUOT, Errno::ENOSPC
      raise DiskFull, "#{build_id} Unable to download artifact bundle: insufficient disk space"
    end

    private

    def artifacts_in_metadata
      files = []
      @metadata.entries.each do |path, metadata|
        next if path.end_with?("/")

        validate_artifact!(path, metadata)
        files << path
      end

      files
    end

    def validate_bundle!
      if @build.artifacts_size > MAX_SIZE
        raise BundleTooLarge,
          "#{build_id}'s artifact bundle is too large: " \
            "#{bytes_to_human_size(@build.artifacts_size)} " \
            "exceeds maximum of #{bytes_to_human_size(MAX_SIZE)}"
      end

      nb_files = @metadata.entries.length
      raise TooManyFiles, "#{build_id} has too many files in bundle (#{nb_files})" if nb_files > MAX_FILES_IN_BUNDLE
    end

    def validate_artifact!(path, metadata_entry)
      raise Error, "#{build_id}: #{path} has invalid metadata" unless metadata_entry

      file_size = metadata_entry[:size]
      return unless file_size > MAX_SIZE

      raise ArtifactTooLarge,
        "#{build_id}: #{path} is too large: " \
          "#{bytes_to_human_size(file_size)} " \
          "exceeds maximum of #{bytes_to_human_size(MAX_SIZE)}"
    end

    def build_id
      "Job #{@build.name} (#{@build.id})"
    end

    def bytes_to_human_size(size)
      ActiveSupport::NumberHelper.number_to_human_size(size)
    end
  end
end
