# frozen_string_literal: true

module Gitlab
  module Counters
    Increment = Struct.new(:amount, :ref, keyword_init: true)
  end
end
