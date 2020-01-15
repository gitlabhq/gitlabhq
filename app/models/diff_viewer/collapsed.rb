# frozen_string_literal: true

module DiffViewer
  class Collapsed < Base
    include Simple
    include Static

    self.partial_name = 'collapsed'
  end
end
