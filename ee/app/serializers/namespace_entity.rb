class NamespaceEntity < Grape::Entity
  expose :id, :name, :path, :kind, :full_path, :parent_id
end
