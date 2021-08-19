# frozen_string_literal: true

class DiffFileMetadataEntity < Grape::Entity
  include DiffFileConflictType

  expose :added_lines
  expose :removed_lines
  expose :new_path
  expose :old_path
  expose :new_file?, as: :new_file
  expose :deleted_file?, as: :deleted_file
  expose :submodule?, as: :submodule
  expose :file_identifier_hash
  expose :file_hash
end
