# frozen_string_literal: true

class Packages::PackageFileBuildInfo < ApplicationRecord
  include IgnorableColumns

  ignore_columns :pipeline_id_convert_to_bigint, remove_with: '17.1', remove_after: '2024-06-14'

  belongs_to :package_file, inverse_of: :package_file_build_infos
  belongs_to :pipeline, class_name: 'Ci::Pipeline'
end
