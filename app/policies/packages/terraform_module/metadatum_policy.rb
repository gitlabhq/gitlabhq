# frozen_string_literal: true

module Packages
  module TerraformModule
    class MetadatumPolicy < BasePolicy
      delegate { @subject.package }
    end
  end
end
