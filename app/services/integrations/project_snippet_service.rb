module Integrations
  class ProjectSnippetService < Integrations::BaseService
    private

    def collection
      project.snippets
    end

    def find_resource
      collection.find_by(id: resource_id)
    end

    def link(snippet)
      Gitlab::Routing.
        url_helpers.
        namespace_project_snippet_url(project.namespace, project, snippet)
    end

    def small_attachment(snippet)
      {
        fallback: snippet.title,
        title: title(snippet),
        title_link: link(snippet),
        text: snippet.content || "", # Slack doesn't like null
      }
    end

    def fields(snippet)
      [
        {
          title: 'Author',
          value: snippet.author.name,
          short: true
        }
      ]
    end
  end
end
