# frozen_string_literal: true

class NoteUserEntity < UserEntity
  unexpose :web_url
end

NoteUserEntity.prepend_mod_with('NoteUserEntity')
