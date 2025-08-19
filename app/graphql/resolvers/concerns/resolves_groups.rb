# frozen_string_literal: true

# Mixin for all resolver classes for type `Types::GroupType.connection_type`.
module ResolvesGroups
  extend ActiveSupport::Concern
  include LooksAhead

  PRELOADS = {
    archived: [:namespace_settings_with_ancestors_inherited_settings],
    container_repositories_count: [:container_repositories],
    description: [:namespace_details],
    description_html: [:namespace_details],
    custom_emoji: [:custom_emoji],
    full_path: [:route],
    path: [:route],
    web_url: [:route],
    dependency_proxy_blob_count: [:dependency_proxy_blobs],
    dependency_proxy_blobs: [:dependency_proxy_blobs],
    dependency_proxy_image_count: [:dependency_proxy_manifests],
    dependency_proxy_image_ttl_policy: [:dependency_proxy_image_ttl_policy],
    dependency_proxy_setting: [:dependency_proxy_setting],
    marked_for_deletion: [:deletion_schedule],
    marked_for_deletion_on: [:deletion_schedule],
    is_self_deletion_scheduled: [:deletion_schedule]
  }.freeze

  def resolve_with_lookahead(*args, **kwargs)
    apply_lookahead(
      resolve_groups(
        *args,
        **kwargs,
        with_statistics: lookahead.selection(:nodes).selects?(:project_statistics)
      )
    )
  end

  private

  # The resolver should implement this method.
  def resolve_groups(**args)
    raise NotImplementedError
  end

  def preloads
    PRELOADS
  end
end

ResolvesGroups.prepend_mod
