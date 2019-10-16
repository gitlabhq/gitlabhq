# frozen_string_literal: true

module BlobViewer
  class Audio < Base
    include Rich
    include ClientSide

    self.partial_name = 'audio'
    self.extensions = UploaderHelper::SAFE_AUDIO_EXT
    self.binary = true
  end
end
