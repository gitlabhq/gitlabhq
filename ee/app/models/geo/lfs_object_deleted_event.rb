module Geo
  class LfsObjectDeletedEvent < ActiveRecord::Base
    include Geo::Model
    include Geo::Eventable

    belongs_to :lfs_object

    validates :lfs_object, :oid, :file_path, presence: true
  end
end
