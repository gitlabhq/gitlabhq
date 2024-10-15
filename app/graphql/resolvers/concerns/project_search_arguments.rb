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
      default_value: 'id_desc',
      description: "Sort order of results. Format: `<field_name>_<sort_direction>`, " \
        "for example: `id_desc` or `name_asc`"
  end

  private

  def project_finder_params(params)
    {
      non_public: params[:membership],
      search: params[:search],
      search_namespaces: params[:search_namespaces],
      sort: params[:sort],
      topic: params[:topics],
      personal: params[:personal]
    }.compact
  end
end
