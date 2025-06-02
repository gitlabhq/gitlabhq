# frozen_string_literal: true

module Types
  module Namespaces
    module MarkdownPaths
      class AutocompleteTypeEnum < BaseEnum
        graphql_name 'AutocompleteType'
        description 'Type of autocomplete source'

        value 'MEMBERS',
          value: 'members',
          description: 'Members autocomplete source.'
        value 'ISSUES',
          value: 'issues',
          description: 'Issues autocomplete source.'
        value 'MERGE_REQUESTS',
          value: 'merge_requests',
          description: 'Merge requests autocomplete source.'
        value 'LABELS',
          value: 'labels',
          description: 'Labels autocomplete source.'
        value 'MILESTONES',
          value: 'milestones',
          description: 'Milestones autocomplete source.'
        value 'COMMANDS',
          value: 'commands',
          description: 'Commands autocomplete source.'
        value 'SNIPPETS',
          value: 'snippets',
          description: 'Snippets autocomplete source (projects only).'
        value 'CONTACTS',
          value: 'contacts',
          description: 'Contacts autocomplete source (projects only).'
        value 'WIKIS',
          value: 'wikis',
          description: 'Wikis autocomplete source (projects only).'
      end
    end
  end
end
