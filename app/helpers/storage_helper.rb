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
      counter_lfs_objects: storage_counter(statistics.lfs_objects_size)
    }

    _("Repository: %{counter_repositories} / Wikis: %{counter_wikis} / Build Artifacts: %{counter_build_artifacts} / LFS: %{counter_lfs_objects}") % counters
  end
end
