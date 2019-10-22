# frozen_string_literal: true

class DiffsMetadataEntity < DiffsEntity
  unexpose :diff_files
  expose :diff_files, using: DiffFileMetadataEntity
end
