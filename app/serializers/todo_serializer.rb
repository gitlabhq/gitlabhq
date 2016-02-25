class TodoSerializer < ActiveModel::Serializer
  attributes :id, :project, :note

  has_one :project
end