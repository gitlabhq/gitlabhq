# frozen_string_literal: true

module DiffViewer
  class NotDiffable < Base
    include Simple
    include Static

    self.partial_name = 'not_diffable'
    self.binary = true
  end
end
