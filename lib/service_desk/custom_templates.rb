# frozen_string_literal: true

module ServiceDesk
  class CustomTemplates
    # Root namespaces created before this keep custom templates
    # unconditionally, so nobody loses a template they already rely on. The
    # date is the permanent rule; the feature flag in the EE override only
    # gates the rollout and is removed afterwards.
    RESTRICTED_FROM_DATE = Date.new(2026, 9, 10)

    def initialize(project)
      @project = project
    end

    # Custom templates are a GitLab.com abuse surface, so the restriction is
    # SaaS-only and lives in the EE override. Self-managed is never affected.
    def enabled?
      true
    end

    private

    attr_reader :project
  end
end

ServiceDesk::CustomTemplates.prepend_mod
