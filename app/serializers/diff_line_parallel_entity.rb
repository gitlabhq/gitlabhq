# frozen_string_literal: true

class DiffLineParallelEntity < Grape::Entity
  expose :left, using: DiffLineEntity
  expose :right, using: DiffLineEntity
end
