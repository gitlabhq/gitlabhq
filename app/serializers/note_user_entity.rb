# frozen_string_literal: true

class NoteUserEntity < UserEntity
  unexpose :web_url

  expose :bot?, as: :bot

  expose :user_type
end

NoteUserEntity.prepend_mod_with('NoteUserEntity')
