# frozen_string_literal: true
module Packages
  module Helm
    class FileMetadatumPolicy < BasePolicy
      delegate { @subject.package_file.package }
    end
  end
end
