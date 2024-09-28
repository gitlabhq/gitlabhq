# frozen_string_literal: true

module StorageHelper
  def storage_counter(size_in_bytes)
    return s_('StorageSize|Unknown') unless size_in_bytes

    precision = size_in_bytes < 1.megabyte ? 0 : 1

    number_to_human_size(size_in_bytes, delimiter: ',', precision: precision, significant: false)
  end

  def storage_counters_details(statistics)
    counters = {
      counter_repositories: storage_counter(statistics.repository_size),
      counter_wikis: storage_counter(statistics.wiki_size),
      counter_build_artifacts: storage_counter(statistics.build_artifacts_size),
      counter_pipeline_artifacts: storage_counter(statistics.pipeline_artifacts_size),
      counter_lfs_objects: storage_counter(statistics.lfs_objects_size),
      counter_snippets: storage_counter(statistics.snippets_size),
      counter_packages: storage_counter(statistics.packages_size),
      counter_uploads: storage_counter(statistics.uploads_size)
    }

    _(
      "Repository: %{counter_repositories} / Wikis: %{counter_wikis} / Build Artifacts: %{counter_build_artifacts} / " \
        "Pipeline Artifacts: %{counter_pipeline_artifacts} / LFS: %{counter_lfs_objects} / " \
        "Snippets: %{counter_snippets} / Packages: %{counter_packages} / Uploads: %{counter_uploads}"
    ) % counters
  end
end
