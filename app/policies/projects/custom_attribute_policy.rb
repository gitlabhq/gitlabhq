# frozen_string_literal: true

module Projects
  class CustomAttributePolicy < ::CustomAttributePolicy
    delegate { @subject.project }
  end
end
