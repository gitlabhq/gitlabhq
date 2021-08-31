# frozen_string_literal: true

module Types
  module Snippets
    class VisibilityScopesEnum < BaseEnum
      value 'private', description: 'Snippet is visible only to the snippet creator.', value: 'are_private'
      value 'internal', description: 'Snippet is visible for any logged in user except external users.', value: 'are_internal'
      value 'public', description: 'Snippet can be accessed without any authentication.', value: 'are_public'
    end
  end
end
