# frozen_string_literal: true

module Boards
  module Lists
    # overridden in EE for board lists and also for epic board lists.
    class DestroyService < Boards::Lists::BaseDestroyService
    end
  end
end
