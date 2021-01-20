# frozen_string_literal: true
module Packages
  module Composer
    class MetadatumPolicy < BasePolicy
      delegate { @subject.package }
    end
  end
end
