# frozen_string_literal: true
module Packages
  module Pypi
    class MetadatumPolicy < BasePolicy
      delegate { @subject.package }
    end
  end
end
