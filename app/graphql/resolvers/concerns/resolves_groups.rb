# frozen_string_literal: true

# Mixin for all resolver classes for type `Types::GroupType.connection_type`.
module ResolvesGroups
  extend ActiveSupport::Concern
  include LooksAhead

  PRELOADS = {
    container_repositories_count: [:container_repositories],
    description: [:namespace_details],
    description_html: [:namespace_details],
    vulnerability_namespace_statistic: [:vulnerability_namespace_statistic],
    custom_emoji: [:custom_emoji],
    full_path: [:route],
    path: [:route],
    web_url: [:route],
    dependency_proxy_blob_count: [:dependency_proxy_blobs],
    dependency_proxy_blobs: [:dependency_proxy_blobs],
    dependency_proxy_image_count: [:dependency_proxy_manifests],
    dependency_proxy_image_ttl_policy: [:dependency_proxy_image_ttl_policy],
    dependency_proxy_setting: [:dependency_proxy_setting],
    analyzer_statuses: [:analyzer_group_statuses]
  }.freeze

  def resolve_with_lookahead(...)
    apply_lookahead(resolve_groups(...))
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
