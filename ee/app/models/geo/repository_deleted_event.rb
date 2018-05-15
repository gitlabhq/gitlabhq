module Geo
  class RepositoryDeletedEvent < ActiveRecord::Base
    include Geo::Model
    include IgnorableColumn

    ignore_column :repository_storage_path

    belongs_to :project

    validates :project, presence: true
  end
end
