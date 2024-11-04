# frozen_string_literal: true

module StartupjsHelper
  def page_startup_graphql_calls
    @graphql_startup_calls
  end

  def page_startup_graphql_headers
    {
      'X-CSRF-Token' => form_authenticity_token,
      'x-gitlab-feature-category' => ::Gitlab::ApplicationContext.current_context_attribute(
        :feature_category
      ).presence || ''
    }
  end

  def add_page_startup_graphql_call(query, variables = {})
    @graphql_startup_calls ||= []
    file_location = File.join(Rails.root, "app/graphql/queries/#{query}.query.graphql")

    return unless File.exist?(file_location)

    query_str = File.read(file_location)
    @graphql_startup_calls << { query: query_str, variables: variables }
  end
end
