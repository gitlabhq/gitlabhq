# frozen_string_literal: true

class DiffsMetadataEntity < DiffsEntity
  unexpose :diff_files
  expose :raw_diff_files, as: :diff_files, using: DiffFileMetadataEntity
end
