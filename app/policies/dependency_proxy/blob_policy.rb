# frozen_string_literal: true
module DependencyProxy
  class BlobPolicy < BasePolicy
    delegate { @subject.group }
  end
end
