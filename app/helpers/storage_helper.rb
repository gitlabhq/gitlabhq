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

    _("Repository: %{counter_repositories} / Wikis: %{counter_wikis} / Build Artifacts: %{counter_build_artifacts} / Pipeline Artifacts: %{counter_pipeline_artifacts} / LFS: %{counter_lfs_objects} / Snippets: %{counter_snippets} / Packages: %{counter_packages} / Uploads: %{counter_uploads}") % counters
  end

  def storage_enforcement_banner_info(namespace)
    return unless can?(current_user, :admin_namespace, namespace)
    return if namespace.paid?
    return unless namespace.storage_enforcement_date && namespace.storage_enforcement_date >= Date.today
    return if user_dismissed_storage_enforcement_banner?(namespace)

    {
      text: html_escape_once(s_("UsageQuota|From %{storage_enforcement_date} storage limits will apply to this namespace. " \
            "View and manage your usage in %{strong_start}%{namespace_type} settings &gt; Usage quotas%{strong_end}.")).html_safe %
            { storage_enforcement_date: namespace.storage_enforcement_date, strong_start: "<strong>".html_safe, strong_end: "</strong>".html_safe, namespace_type: namespace.type },
      variant: 'warning',
      callouts_path: namespace.user_namespace? ? callouts_path : group_callouts_path,
      callouts_feature_name: storage_enforcement_banner_user_callouts_feature_name(namespace),
      learn_more_link: link_to(_('Learn more.'), help_page_path('/'), rel: 'noopener noreferrer', target: '_blank') # TBD: https://gitlab.com/gitlab-org/gitlab/-/issues/350632
    }
  end

  private

  def storage_enforcement_banner_user_callouts_feature_name(namespace)
    "storage_enforcement_banner_#{storage_enforcement_banner_threshold(namespace)}_enforcement_threshold"
  end

  def storage_enforcement_banner_threshold(namespace)
    days_to_enforcement_date = (namespace.storage_enforcement_date - Date.today)

    return :first if days_to_enforcement_date > 30
    return :second if days_to_enforcement_date > 15 && days_to_enforcement_date <= 30
    return :third if days_to_enforcement_date > 7 && days_to_enforcement_date <= 15
    return :fourth if days_to_enforcement_date >= 0 && days_to_enforcement_date <= 7
  end

  def user_dismissed_storage_enforcement_banner?(namespace)
    return false unless current_user

    if namespace.user_namespace?
      current_user.dismissed_callout?(feature_name: storage_enforcement_banner_user_callouts_feature_name(namespace))
    else
      current_user.dismissed_callout_for_group?(feature_name: storage_enforcement_banner_user_callouts_feature_name(namespace),
                                                group: namespace)
    end
  end
end
