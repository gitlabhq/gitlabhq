# frozen_string_literal: true

class Namespace::PackageSettingPolicy < BasePolicy
  delegate { @subject.namespace }
end
