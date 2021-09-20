# frozen_string_literal: true
module DependencyProxy
  class ImageTtlGroupPolicyPolicy < BasePolicy
    delegate { @subject.group }
  end
end
