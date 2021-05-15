# frozen_string_literal: true
module Packages
  module Nuget
    class MetadatumPolicy < BasePolicy
      delegate { @subject.package }
    end
  end
end
