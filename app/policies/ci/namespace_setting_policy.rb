# frozen_string_literal: true

module Ci
  class NamespaceSettingPolicy < BasePolicy
    delegate { @subject.namespace }
  end
end
