# frozen_string_literal: true

module Gitlab
  module Observability
    module_function

    ACTION_TO_PERMISSION = {
      explore: :read_observability,
      datasources: :admin_observability,
      manage: :admin_observability,
      dashboards: :read_observability
    }.freeze

    def observability_url
      return ENV['OVERRIDE_OBSERVABILITY_URL'] if ENV['OVERRIDE_OBSERVABILITY_URL']
      # TODO Make observability URL configurable https://gitlab.com/gitlab-org/opstrace/opstrace-ui/-/issues/80
      return 'https://observe.staging.gitlab.com' if Gitlab.staging?

      'https://observe.gitlab.com'
    end

    def valid_observability_url?(url)
      uri = URI.parse(url)
      observability_uri = URI.parse(Gitlab::Observability.observability_url)

      uri.scheme == observability_uri.scheme &&
        uri.port == observability_uri.port &&
        uri.host.casecmp?(observability_uri.host)

    rescue URI::InvalidURIError
      false
    end

    def group_id_from_url(url)
      return unless valid_observability_url?(url)

      group_id = URI.parse(url).path.split('/')[1]
      group_id.to_i unless group_id.to_i <= 0
    end

    def allowed_for_action?(user, group, action)
      return false if action.nil?

      permission = ACTION_TO_PERMISSION.fetch(action.to_sym, :admin_observability)
      allowed?(user, group, permission)
    end

    def allowed?(user, group, permission = :admin_observability)
      return false unless group && user

      Gitlab::Observability.observability_url.present? && Ability.allowed?(user, permission, group)
    end
  end
end
