# frozen_string_literal: true

class NamespaceBasicEntity < Grape::Entity
  expose :id
  expose :full_path
end
