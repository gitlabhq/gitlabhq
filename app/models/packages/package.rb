class Packages::Package < ActiveRecord::Base
  belongs_to :project
  has_many :package_files
  has_one :maven_metadatum
end
