# frozen_string_literal: true

module Gitlab
  module Observability
    module_function

    def observability_url
      return ENV['OVERRIDE_OBSERVABILITY_URL'] if ENV['OVERRIDE_OBSERVABILITY_URL']
      # TODO Make observability URL configurable https://gitlab.com/gitlab-org/opstrace/opstrace-ui/-/issues/80
      return 'https://observe.staging.gitlab.com' if Gitlab.staging?

      'https://observe.gitlab.com'
    end

    def observability_enabled?(user, group)
      Gitlab::Observability.observability_url.present? && Ability.allowed?(user, :read_observability, group)
    end
  end
end
