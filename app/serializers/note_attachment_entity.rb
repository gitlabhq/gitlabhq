# frozen_string_literal: true

class NoteAttachmentEntity < Grape::Entity
  expose :url
  expose :filename
  expose :image?, as: :image
end
