# frozen_string_literal: true

class Packages::PackageFileBuildInfo < ApplicationRecord
  include Ci::Partitionable::AssociationFinder

  belongs_to :package_file, inverse_of: :package_file_build_infos
  belongs_to :pipeline, class_name: 'Ci::Pipeline'
  partitionable_belongs_to_loader :pipeline
end
