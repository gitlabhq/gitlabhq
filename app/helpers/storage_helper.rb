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
    root_ancestor = namespace.root_ancestor

    return unless can?(current_user, :maintain_namespace, root_ancestor)
    return if root_ancestor.paid?
    return unless future_enforcement_date?(root_ancestor)
    return if user_dismissed_storage_enforcement_banner?(root_ancestor)

    {
      text: html_escape_once(s_("UsageQuota|From %{storage_enforcement_date} storage limits will apply to this namespace. " \
            "You are currently using %{used_storage} of namespace storage. " \
            "View and manage your usage from %{strong_start}%{namespace_type} settings &gt; Usage quotas%{strong_end}.")).html_safe %
            { storage_enforcement_date: root_ancestor.storage_enforcement_date, used_storage: storage_counter(root_ancestor.root_storage_statistics&.storage_size || 0), strong_start: "<strong>".html_safe, strong_end: "</strong>".html_safe, namespace_type: root_ancestor.type },
      variant: 'warning',
      callouts_path: root_ancestor.user_namespace? ? callouts_path : group_callouts_path,
      callouts_feature_name: storage_enforcement_banner_user_callouts_feature_name(root_ancestor),
      learn_more_link: link_to(_('Learn more.'), help_page_path('/'), rel: 'noopener noreferrer', target: '_blank')
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
      current_user.dismissed_callout_for_group?(
        feature_name: storage_enforcement_banner_user_callouts_feature_name(namespace),
        group: namespace
      )
    end
  end

  def future_enforcement_date?(namespace)
    return true if ::Feature.enabled?(:namespace_storage_limit_bypass_date_check, namespace)

    namespace.storage_enforcement_date.present? && namespace.storage_enforcement_date >= Date.today
  end
end
