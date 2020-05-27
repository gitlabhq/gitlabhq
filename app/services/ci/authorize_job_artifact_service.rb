# frozen_string_literal: true

module Ci
  class AuthorizeJobArtifactService
    include Gitlab::Utils::StrongMemoize

    # Max size of the zipped LSIF artifact
    LSIF_ARTIFACT_MAX_SIZE = 20.megabytes
    LSIF_ARTIFACT_TYPE = 'lsif'

    def initialize(job, params, max_size:)
      @job = job
      @max_size = max_size
      @size = params[:filesize]
      @type = params[:artifact_type].to_s
    end

    def forbidden?
      lsif? && !code_navigation_enabled?
    end

    def too_large?
      size && max_size <= size.to_i
    end

    def headers
      default_headers = JobArtifactUploader.workhorse_authorize(has_length: false, maximum_size: max_size)
      default_headers.tap do |h|
        h[:ProcessLsif] = true if lsif? && code_navigation_enabled?
      end
    end

    private

    attr_reader :job, :size, :type

    def code_navigation_enabled?
      strong_memoize(:code_navigation_enabled) do
        Feature.enabled?(:code_navigation, job.project)
      end
    end

    def lsif?
      strong_memoize(:lsif) do
        type == LSIF_ARTIFACT_TYPE
      end
    end

    def max_size
      lsif? ? LSIF_ARTIFACT_MAX_SIZE : @max_size.to_i
    end
  end
end
