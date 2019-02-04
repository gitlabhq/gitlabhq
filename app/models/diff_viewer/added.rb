# frozen_string_literal: true

module DiffViewer
  class Added < Base
    include Simple
    include Static

    self.partial_name = 'added'
  end
end
