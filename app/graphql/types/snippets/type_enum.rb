# frozen_string_literal: true

module Types
  module Snippets
    class TypeEnum < BaseEnum
      value 'personal', description: 'Snippet created independent of any project.', value: 'personal'
      value 'project', description: 'Snippet related to a specific project.', value: 'project'
    end
  end
end
