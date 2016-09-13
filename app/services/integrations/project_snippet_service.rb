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
      "[$#{snippet.id} #{snippet.title}](#{link(snippet)})"
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
  end
end
