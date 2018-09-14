# frozen_string_literal: true

module ActiveSupport
  module Concern
    prepend Gitlab::Patch::Prependable
  end
end
