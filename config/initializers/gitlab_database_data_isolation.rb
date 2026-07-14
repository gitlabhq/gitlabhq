# frozen_string_literal: true

sharding_key_map = Gitlab::Database::Dictionary.entries.each_with_object({}) do |entry, map|
  sharding_key = entry.sharding_key
  # Tables with multiple sharding keys are excluded: scoping them requires an
  # OR condition across the keys, which performs poorly. See
  # https://gitlab.com/gitlab-org/gitlab/-/issues/594726
  next unless sharding_key.is_a?(Hash) && sharding_key.size == 1

  map[entry.key_name] = sharding_key.transform_values(&:to_sym)
end

Gitlab::Database::DataIsolation.configure do |config|
  config.strategy = :arel
  config.sharding_key_map = sharding_key_map
  config.current_sharding_key_value = ->(type) {
    return unless Gitlab::Organizations::Isolation.enabled?

    organization_id = Current.organization&.id if Current.organization_assigned
    return unless organization_id

    case type
    when :projects
      Project.select(:id).in_organization(organization_id)
    when :namespaces
      Namespace.select(:id).in_organization(organization_id)
    when :organizations
      organization_id
    when :users
      User.select(:id).in_organization(organization_id)
    end
  }
end

Gitlab::Database::DataIsolation.install!
