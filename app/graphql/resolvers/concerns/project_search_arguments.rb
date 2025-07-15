# frozen_string_literal: true

module ProjectSearchArguments
  extend ActiveSupport::Concern

  included do
    argument :membership, GraphQL::Types::Boolean,
      required: false,
      description: 'Return only projects that the current user is a member of.'

    argument :search, GraphQL::Types::String,
      required: false,
      description: 'Search query, which can be for the project name, a path, or a description.'

    argument :search_namespaces, GraphQL::Types::Boolean,
      required: false,
      description: 'Include namespace in project search.'

    argument :topics, type: [GraphQL::Types::String],
      required: false,
      description: 'Filter projects by topics.'

    argument :personal, GraphQL::Types::Boolean,
      required: false,
      description: 'Return only personal projects.'

    argument :sort, GraphQL::Types::String,
      required: false,
      default_value: nil,
      description: "Sort order of results. Format: `<field_name>_<sort_direction>`, " \
        "for example: `id_desc` or `name_asc`. Defaults to `id_desc`, or `similarity` if search used."

    argument :namespace_path, GraphQL::Types::ID,
      required: false,
      description: "Filter projects by their namespace's full path (group or user)."
  end

  private

  def project_finder_params(params)
    {
      non_public: params[:membership],
      search: params[:search],
      search_namespaces: params[:search_namespaces],
      sort: params[:sort],
      topic: params[:topics],
      personal: params[:personal],
      namespace_path: params[:namespace_path]
    }.compact
  end
end
