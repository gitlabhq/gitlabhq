# frozen_string_literal: true
module DependencyProxy
  class ManifestPolicy < BasePolicy
    delegate { @subject.group }
  end
end
