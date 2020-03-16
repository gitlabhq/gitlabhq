# frozen_string_literal: true

module Ci
  # This class loops through all builds with exposed artifacts and returns
  # basic information about exposed artifacts for given jobs for the frontend
  # to display them as custom links in the merge request.
  #
  # This service must be used with care.
  # Looking for exposed artifacts is very slow and should be done asynchronously.
  class FindExposedArtifactsService < ::BaseService
    include Gitlab::Routing

    MAX_EXPOSED_ARTIFACTS = 10

    def for_pipeline(pipeline, limit: MAX_EXPOSED_ARTIFACTS)
      results = []

      pipeline.builds.latest.with_exposed_artifacts.find_each do |job|
        if job_exposed_artifacts = for_job(job)
          results << job_exposed_artifacts
        end

        break if results.size >= limit
      end

      results
    end

    def for_job(job)
      return unless job.has_exposed_artifacts?

      metadata_entries = first_2_metadata_entries_for_artifacts_paths(job)
      return if metadata_entries.empty?

      {
        text: job.artifacts_expose_as,
        url: path_for_entries(metadata_entries, job),
        job_path: project_job_path(job.project, job),
        job_name: job.name
      }
    end

    private

    # we don't need to fetch all artifacts entries for a job because
    # it could contain many. We only need to know whether it has 1 or more
    # artifacts, so fetching the first 2 would be sufficient.
    def first_2_metadata_entries_for_artifacts_paths(job)
      return [] unless job.artifacts_metadata

      job.artifacts_paths
        .lazy
        .map { |path| job.artifacts_metadata_entry(path, recursive: true) }
        .select { |entry| entry.exists? }
        .first(2)
    end

    def path_for_entries(entries, job)
      return if entries.empty?

      if single_artifact?(entries)
        file_project_job_artifacts_path(job.project, job, entries.first.path)
      else
        browse_project_job_artifacts_path(job.project, job)
      end
    end

    def single_artifact?(entries)
      entries.size == 1 && entries.first.file?
    end
  end
end
