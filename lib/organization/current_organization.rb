# frozen_string_literal: true

module Organization
  module CurrentOrganization
    CURRENT_ORGANIZATION_THREAD_VAR = :current_organization

    def current_organization
      Thread.current[CURRENT_ORGANIZATION_THREAD_VAR]
    end

    def current_organization=(organization)
      Thread.current[CURRENT_ORGANIZATION_THREAD_VAR] = organization
    end

    def with_current_organization(organization, &_blk)
      previous_organization = current_organization
      self.current_organization = organization
      yield
    ensure
      self.current_organization = previous_organization
    end
  end
end
