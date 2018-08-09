# frozen_string_literal: true

module DiffViewer
  class Renamed < Base
    include Simple
    include Static

    self.partial_name = 'renamed'
  end
end
