# frozen_string_literal: true

module Users
  class GroupCalloutPolicy < BasePolicy
    delegate { @subject.user }
  end
end
