module Integrations
  class ProjectSnippetService < BaseService

    private

    def klass
      ProjectSnippet
    end

    def find_resource
      collection.find_by(id: params[:text])
    end

    def title(snippet)
      format("$#{snippet.id} #{snippet.title}")
    end

    def link(snippet)
      Gitlab::Routing.url_helpers.namespace_project_snippet_url(project.namespace,
                                                                project, snippet)
    end

    def attachment(snippet)
      {
        text: slack_format(snippet.content),
        color: '#C95823',
      }
    end

    def small_attachment(snippet)
      {
        fallback: snippet.title,
        title: title(snippet),
        title_link: link(snippet),
        text: snippet.description || "", # Slack doesn't like null
        color: '#345'
      }
    end

    def fields(snippet)
      [
        {
          title: 'Author',
          value: snippet.author,
          short: true
        }
      ]
    end
  end
end
