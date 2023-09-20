# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class Diff
      ATTRS = %i[from_path to_path old_mode new_mode from_id to_id patch overflow_marker collapsed too_large].freeze

      include AttributesBag
    end
  end
end
