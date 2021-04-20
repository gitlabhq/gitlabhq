# frozen_string_literal: true
module Packages
  module Conan
    class MetadatumPolicy < BasePolicy
      delegate { @subject.package }
    end
  end
end
