# frozen_string_literal: true

module Types
  module Snippets
    class VisibilityScopesEnum < BaseEnum
      value 'private',  value: 'are_private'
      value 'internal', value: 'are_internal'
      value 'public',   value: 'are_public'
    end
  end
end
