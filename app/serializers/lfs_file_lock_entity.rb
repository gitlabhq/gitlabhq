# frozen_string_literal: true

class LfsFileLockEntity < Grape::Entity
  root 'locks', 'lock'

  expose :path
  expose(:id) { |entity| entity.id.to_s }
  expose(:created_at, as: :locked_at) { |entity| entity.created_at.to_fs(:iso8601) }

  expose :owner do
    expose(:name) { |entity| entity.user&.username }
  end
end
