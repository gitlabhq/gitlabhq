# frozen_string_literal: true

module API
  module Entities
    class MirrorHostKey < Grape::Entity
      expose :fingerprint_sha256, documentation: { type: 'String', example: 'SHA256:abcd1234' }
    end
  end
end
