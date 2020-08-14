# frozen_string_literal: true

class GroupDeployKeysGroupEntity < Grape::Entity
  expose :can_push
  expose :group, using: GroupBasicEntity
end
