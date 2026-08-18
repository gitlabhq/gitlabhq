# frozen_string_literal: true

require 'fog/google'

# Uploads generated Pact consumer contracts to the gitlab-rails-consumer-contracts
# GCS bucket, organised by service slug and GitLab version:
#
#   gs://<GCS_BUCKET>/<service-slug>/<gitlab-version>/<contract-filename>
#
# Service slugs are derived from the immediate subdirectory names of contracts_dir.
# Both directory names and GCS slugs use underscores (e.g. artifact_registry/).
# Only contract filenames use hyphens (e.g. gitlab-rails-artifact-registry-repositories-get.json).
#
# Each CI job scopes contracts_dir to one service, so this script
# uploads contracts for that service only.
#
# Required environment variables:
#   GCS_BUCKET                         - GCS bucket name
#                                        (e.g. 'gitlab-rails-consumer-contracts')
#   RAILS_CONSUMER_CONTRACT_GCS_BUCKET_KEY
#                                      - Path to a GCS service account JSON key file,
#                                        or the JSON key content as a string
#
# Version resolution (first match wins):
#   GITLAB_VERSION         - GitLab release version string (e.g. '18.0').
#                            Pass this when running locally.
#   CI_COMMIT_REF_NAME     - Set automatically in CI. The stable branch name
#                            (e.g. '18-0-stable-ee') is parsed to produce '18.0'.
# rubocop:disable Gitlab/NamespacedClass -- standalone script loaded outside Rails autoload
class GcsContractUploader
  # rubocop:enable Gitlab/NamespacedClass
  CONTRACTS_SUBPATH = 'contracts/external'
  # Matches stable branch names like '18-0-stable-ee' or '17-11-stable-ee'
  STABLE_BRANCH_RE  = /^(\d+)-(\d+)-stable-ee$/
  VERSION_ERROR_MSG = "Cannot determine GitLab version: set GITLAB_VERSION or run in CI on a " \
    "stable branch (e.g. '18-0-stable-ee')."

  def initialize(env: ENV, contracts_dir: nil)
    @env           = env
    @contracts_dir = contracts_dir || File.join(
      File.expand_path('../../../..', __dir__),
      'spec', 'contracts', CONTRACTS_SUBPATH
    )
  end

  def upload!
    validate_env!
    upload_contracts!
  end

  private

  attr_reader :env, :contracts_dir

  # -- Validation ------------------------------------------------------------

  def validate_env!
    raise ArgumentError, 'GCS_BUCKET environment variable is required' if blank?(gcs_bucket)

    if blank?(gcs_json_key)
      raise ArgumentError, 'RAILS_CONSUMER_CONTRACT_GCS_BUCKET_KEY environment variable is required'
    end

    # Eagerly resolve the version so any misconfiguration is caught up front.
    gitlab_version
  end

  # -- GCS client ------------------------------------------------------------

  # Returns a memoized fog-google directory scoped to gcs_bucket.
  #
  # Using the directories/files API (rather than raw put_object) ensures
  # that objects are created even when the key prefix does not yet exist,
  # and that existing objects are overwritten without requiring
  # storage.objects.delete permission.
  #
  # Automatically detects whether gcs_json_key is a file path
  # (uses google_json_key_location) or a JSON string
  # (uses google_json_key_string) for authentication.
  #
  # @return [Fog::Google::StorageJSON::Directory]
  # @raise [SystemExit] if the JSON key is invalid
  def gcs_directory
    key_opt = if File.exist?(gcs_json_key)
                { google_json_key_location: gcs_json_key }
              else
                { google_json_key_string: gcs_json_key }
              end

    storage = Fog::Google::Storage.new(google_project: gcs_bucket, **key_opt)
    @gcs_directory ||= storage.directories.new(key: gcs_bucket)
  rescue StandardError
    abort("\nThere might be something wrong with the JSON key.")
  end

  # -- Upload ----------------------------------------------------------------

  def upload_contracts!
    raise "Contracts directory not found: #{contracts_dir}" unless Dir.exist?(contracts_dir)

    service_slugs = discover_service_slugs
    raise "No service subdirectories found in #{contracts_dir}" if service_slugs.empty?

    errors   = []
    uploaded = 0

    service_slugs.each do |slug|
      slug_dir  = File.join(contracts_dir, slug)
      contracts = Dir.glob(File.join(slug_dir, '*.json'))

      if contracts.empty?
        warn "WARNING: No contract JSON files found for service '#{slug}' in #{slug_dir}, skipping."
        next
      end

      destination_prefix = "#{slug}/#{gitlab_version}"

      contracts.each do |contract|
        filename    = File.basename(contract)
        object_path = "#{destination_prefix}/#{filename}"

        puts "Uploading #{filename} -> gs://#{gcs_bucket}/#{object_path}"
        begin
          gcs_directory.files.create(key: object_path, body: File.read(contract)) # rubocop:disable Rails/SaveBang -- fog-google Files does not implement create!
          uploaded += 1
        rescue StandardError => e
          warn "ERROR: Failed to upload #{contract}: #{e}"
          errors << contract
        end
      end

      puts "Uploaded contracts for '#{slug}' to gs://#{gcs_bucket}/#{destination_prefix}"
    end

    raise "#{errors.size} contract(s) failed to upload" unless errors.empty?

    puts "Uploaded #{uploaded} contract(s)."
  end

  # Returns the immediate subdirectory names of contracts_dir, each used as the
  # GCS slug directly. Both dirs and GCS slugs use underscores (e.g. 'artifact_registry').
  def discover_service_slugs
    dirs = Dir.children(contracts_dir).select do |entry|
      File.directory?(File.join(contracts_dir, entry))
    end

    dirs.sort
  end

  # -- Helpers ---------------------------------------------------------------

  # Resolves the GitLab version string used as the GCS path segment.
  #
  # Resolution order:
  #   1. GITLAB_VERSION env var -- use this when running locally.
  #   2. CI_COMMIT_REF_NAME    -- parsed from the stable branch name in CI
  #                               (e.g. '18-0-stable-ee' -> '18.0').
  def gitlab_version
    return @gitlab_version if @gitlab_version

    ver = env['GITLAB_VERSION']
    return @gitlab_version = ver.strip unless blank?(ver)

    ref   = env['CI_COMMIT_REF_NAME'].to_s
    match = STABLE_BRANCH_RE.match(ref)

    raise "#{VERSION_ERROR_MSG} Got CI_COMMIT_REF_NAME=#{ref.inspect}" unless match

    @gitlab_version = "#{match[1]}.#{match[2]}"
  end

  # rubocop:disable Style/EndlessMethod -- concise accessors, intentional
  def gcs_bucket   = env['GCS_BUCKET']
  def gcs_json_key = env['RAILS_CONSUMER_CONTRACT_GCS_BUCKET_KEY']

  # rubocop:enable Style/EndlessMethod

  def blank?(val)
    !val.is_a?(String) || val.strip.empty?
  end
end

GcsContractUploader.new.upload! if __FILE__ == $PROGRAM_NAME
