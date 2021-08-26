# frozen_string_literal: true
module DependencyProxy
  class GroupSettingPolicy < BasePolicy
    delegate { @subject.group }
  end
end
