# frozen_string_literal: true

class MoveToProjectEntity < Grape::Entity
  expose :id
  expose :name_with_namespace
  expose :full_path
end
