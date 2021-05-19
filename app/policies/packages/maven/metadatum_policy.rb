# frozen_string_literal: true
module Packages
  module Maven
    class MetadatumPolicy < BasePolicy
      delegate { @subject.package }
    end
  end
end
