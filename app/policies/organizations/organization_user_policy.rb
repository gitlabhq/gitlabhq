# frozen_string_literal: true

module Organizations
  class OrganizationUserPolicy < BasePolicy
    delegate :organization

    condition(:last_owner?) { @subject.last_owner? }

    rule { ~last_owner? }.enable :remove_user
  end
end
