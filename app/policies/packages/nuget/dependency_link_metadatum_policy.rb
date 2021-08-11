# frozen_string_literal: true
module Packages
  module Nuget
    class DependencyLinkMetadatumPolicy < BasePolicy
      delegate { @subject.dependency_link.package }
    end
  end
end
