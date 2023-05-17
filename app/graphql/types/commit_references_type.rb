# frozen_string_literal: true

module Types
  class CommitReferencesType < BaseObject
    graphql_name 'CommitReferences'

    authorize :read_commit

    def self.field_for_tipping_refs(field_name, field_description)
      field field_name, ::Types::Projects::CommitParentNamesType,
        null: true,
        calls_gitaly: true,
        description: field_description do
          argument :limit, GraphQL::Types::Int,
            required: true,
            default_value: 100,
            description: 'Number of ref names to return.',
            validates: { numericality: { within: 1..1000 } }
        end
    end

    def self.field_for_containing_refs(field_name, field_description)
      field field_name, ::Types::Projects::CommitParentNamesType,
        null: true,
        calls_gitaly: true,
        description: field_description do
        argument :exclude_tipped, GraphQL::Types::Boolean,
          required: true,
          default_value: false,
          description: 'Exclude tipping refs. WARNING: This argument can be confusing, if there is a limit.
          for example set the limit to 5 and in the 5 out a total of 25 refs there is 2 tipped refs,
          then the method will only 3 refs, even though there is more.'
        # rubocop: disable GraphQL/ArgumentUniqueness
        argument :limit, GraphQL::Types::Int,
          required: true,
          default_value: 100,
          description: 'Number of ref names to return.',
          validates: { numericality: { within: 1..1000 } }
        # rubocop: enable GraphQL/ArgumentUniqueness
      end
    end

    field_for_tipping_refs :tipping_tags, "Get tag names tipping at a given commit."

    field_for_tipping_refs :tipping_branches, "Get branch names tipping at a given commit."

    field_for_containing_refs :containing_tags, "Get tag names containing a given commit."

    field_for_containing_refs :containing_branches, "Get branch names containing a given commit."

    def tipping_tags(limit:)
      { names: object.tipping_tags(limit: limit) }
    end

    def tipping_branches(limit:)
      { names: object.tipping_branches(limit: limit) }
    end

    def containing_tags(limit:, exclude_tipped:)
      { names: object.tags_containing(limit: limit, exclude_tipped: exclude_tipped) }
    end

    def containing_branches(limit:, exclude_tipped:)
      { names: object.branches_containing(limit: limit, exclude_tipped: exclude_tipped) }
    end
  end
end
