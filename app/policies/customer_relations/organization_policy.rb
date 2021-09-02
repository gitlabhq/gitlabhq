# frozen_string_literal: true
module CustomerRelations
  class OrganizationPolicy < BasePolicy
    delegate { @subject.group }
  end
end
