# frozen_string_literal: true

module Banzai
  # Object storing the current user, project, and other details used when
  # parsing Markdown references.
  class RenderContext
    attr_reader :current_user, :options

    # default_project - The default project to use for all documents, if any.
    # current_user - The user viewing the document, if any.
    def initialize(default_project = nil, current_user = nil, options: {})
      @current_user = current_user
      @projects = Hash.new(default_project)
      @options = options
    end

    # Associates an HTML document with a Project.
    #
    # document - The HTML document to map to a Project.
    # object - The object that produced the HTML document.
    def associate_document(document, object)
      # XML nodes respond to "document" but will return a Document instance,
      # even when they belong to a DocumentFragment.
      document = document.document if document.fragment?

      @projects[document] = object.project if object.respond_to?(:project)
    end

    def project_for_node(node)
      @projects[node.document]
    end
  end
end
