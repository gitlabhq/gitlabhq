# frozen_string_literal: true

class Packages::PackageFileBuildInfo < ApplicationRecord
  belongs_to :package_file, inverse_of: :package_file_build_infos
  belongs_to :pipeline, class_name: 'Ci::Pipeline'
end
