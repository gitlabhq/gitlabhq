# frozen_string_literal: true
module Packages
  class PackageFilePolicy < BasePolicy
    delegate { @subject.package }
  end
end
