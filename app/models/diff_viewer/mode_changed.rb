# frozen_string_literal: true

module DiffViewer
  class ModeChanged < Base
    include Simple
    include Static

    self.partial_name = 'mode_changed'
  end
end
