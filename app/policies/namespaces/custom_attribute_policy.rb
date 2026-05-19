# frozen_string_literal: true

module Namespaces
  class CustomAttributePolicy < ::CustomAttributePolicy
    delegate { @subject.group }
  end
end
