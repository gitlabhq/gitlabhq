# frozen_string_literal: true

module ResolvesSnippets
  extend ActiveSupport::Concern
  include ResolvesIds

  included do
    type Types::SnippetType.connection_type, null: true

    argument :ids, [::Types::GlobalIDType[::Snippet]],
      required: false,
      description: 'Array of global snippet IDs. For example, `gid://gitlab/ProjectSnippet/1`.'

    argument :visibility, Types::Snippets::VisibilityScopesEnum,
      required: false,
      description: 'Visibility of the snippet.'
  end

  def resolve(**args)
    resolve_snippets(args)
  end

  private

  def resolve_snippets(args)
    SnippetsFinder.new(context[:current_user], snippet_finder_params(args)).execute
  end

  def snippet_finder_params(args)
    {
      ids: resolve_ids(args[:ids]),
      scope: args[:visibility]
    }.merge(options_by_type(args[:type]))
  end

  def options_by_type(type)
    case type
    when 'personal'
      { only_personal: true }
    when 'project'
      { only_project: true }
    else
      {}
    end
  end
end
