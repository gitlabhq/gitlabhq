# frozen_string_literal: true

module API
  module Entities
    class MirrorHostKey < Grape::Entity
      expose :fingerprint_sha256
    end
  end
end
