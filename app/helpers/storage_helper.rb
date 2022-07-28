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

  def storage_enforcement_banner_info(context)
    root_ancestor = context.root_ancestor

    return unless should_show_storage_enforcement_banner?(context, current_user, root_ancestor)

    text_args = storage_enforcement_banner_text_args(root_ancestor, context)

    text_paragraph_2 = if root_ancestor.user_namespace?
                         html_escape_once(s_("UsageQuota|The namespace is currently using %{strong_start}%{used_storage}%{strong_end} of namespace storage. " \
                           "View and manage your usage from %{strong_start}User settings &gt; Usage quotas%{strong_end}. %{docs_link_start}Learn more%{link_end} " \
                           "about how to reduce your storage.")).html_safe % text_args[:p2]
                       else
                         html_escape_once(s_("UsageQuota|The namespace is currently using %{strong_start}%{used_storage}%{strong_end} of namespace storage. " \
                           "View and manage your usage from %{strong_start}Group settings &gt; Usage quotas%{strong_end}. %{docs_link_start}Learn more%{link_end} " \
                           "about how to reduce your storage.")).html_safe % text_args[:p2]
                       end

    {
      text_paragraph_1: html_escape_once(s_("UsageQuota|Effective %{storage_enforcement_date}, %{announcement_link_start}namespace storage limits will apply%{link_end} " \
            "to the %{strong_start}%{namespace_name}%{strong_end} namespace. %{extra_message}" \
            "View the %{rollout_link_start}rollout schedule for this change%{link_end}.")).html_safe % text_args[:p1],
      text_paragraph_2: text_paragraph_2,
      text_paragraph_3: html_escape_once(s_("UsageQuota|See our %{faq_link_start}FAQ%{link_end} for more information.")).html_safe % text_args[:p3],
      variant: 'warning',
      namespace_id: root_ancestor.id,
      callouts_path: root_ancestor.user_namespace? ? callouts_path : group_callouts_path,
      callouts_feature_name: storage_enforcement_banner_user_callouts_feature_name(root_ancestor)
    }
  end

  private

  def should_show_storage_enforcement_banner?(context, current_user, root_ancestor)
    return false unless user_allowed_storage_enforcement_banner?(context, current_user, root_ancestor)
    return false if root_ancestor.paid?
    return false unless future_enforcement_date?(root_ancestor)
    return false if user_dismissed_storage_enforcement_banner?(root_ancestor)

    ::Feature.enabled?(:namespace_storage_limit_show_preenforcement_banner, root_ancestor)
  end

  def user_allowed_storage_enforcement_banner?(context, current_user, root_ancestor)
    return can?(current_user, :maintainer_access, context) unless context.respond_to?(:user_namespace?) && context.user_namespace?

    can?(current_user, :owner_access, context)
  end

  def storage_enforcement_banner_text_args(root_ancestor, context)
    strong_tags = {
      strong_start: "<strong>".html_safe,
      strong_end: "</strong>".html_safe
    }

    extra_message = if context.is_a?(Project)
                      html_escape_once(s_("UsageQuota|The %{strong_start}%{context_name}%{strong_end} project will be affected by this. "))
                        .html_safe % strong_tags.merge(context_name: context.name)
                    elsif !context.root?
                      html_escape_once(s_("UsageQuota|The %{strong_start}%{context_name}%{strong_end} group will be affected by this. "))
                        .html_safe % strong_tags.merge(context_name: context.name)
                    else
                      ''
                    end

    {
      p1: {
        storage_enforcement_date: root_ancestor.storage_enforcement_date,
        namespace_name: root_ancestor.name,
        extra_message: extra_message,
        announcement_link_start: '<a href="%{url}" >'.html_safe % { url: "#{Gitlab::Saas.community_forum_url}/t/gitlab-introduces-storage-and-transfer-limits-for-users-on-saas/69883" },
        rollout_link_start: '<a href="%{url}" >'.html_safe % { url: help_page_path('user/usage_quotas', anchor: 'tbd') },
        link_end: "</a>".html_safe
      }.merge(strong_tags),
      p2: {
        used_storage: storage_counter(root_ancestor.root_storage_statistics&.storage_size || 0),
        docs_link_start: '<a href="%{url}" >'.html_safe % { url: help_page_path('user/usage_quotas', anchor: 'manage-your-storage-usage') },
        link_end: "</a>".html_safe
      }.merge(strong_tags),
      p3: {
        faq_link_start: '<a href="%{url}" >'.html_safe % { url: "#{Gitlab::Saas.about_pricing_url}faq-efficient-free-tier/#storage-and-transfer-limits-on-gitlab-saas-free-tier" },
        link_end: "</a>".html_safe
      }
    }
  end

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
