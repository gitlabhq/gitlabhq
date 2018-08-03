class Packages::MavenMetadatum < ActiveRecord::Base
  belongs_to :package

  validates :package, presence: true
end
