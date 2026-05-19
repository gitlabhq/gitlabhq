# frozen_string_literal: true

module Users
  class CustomAttributePolicy < ::CustomAttributePolicy
    delegate { @subject.user }
  end
end
