module Banzai
  # Class for rendering multiple objects (e.g. Note instances) in a single pass.
  #
  # Rendered Markdown is stored in an attribute in every object based on the
  # name of the attribute containing the Markdown. For example, when the
  # attribute `note` is rendered the HTML is stored in `note_html`.
  class ObjectRenderer
    attr_reader :project, :user

    # Make sure to set the appropriate pipeline in the `raw_context` attribute
    # (e.g. `:note` for Note instances).
    #
    # project - A Project to use for rendering and redacting Markdown.
    # user - The user viewing the Markdown/HTML documents, if any.
    # context - A Hash containing extra attributes to use in the rendering
    #           pipeline.
    def initialize(project, user = nil, raw_context = {})
      @project = project
      @user = user
      @raw_context = raw_context
    end

    # Renders and redacts an Array of objects.
    #
    # objects - The objects to render
    # attribute - The attribute containing the raw Markdown to render.
    #
    # Returns the same input objects.
    def render(objects, attribute)
      documents = render_objects(objects, attribute)
      redacted = redact_documents(documents)

      objects.each_with_index do |object, index|
        redacted_data = redacted[index]
        object.__send__("#{attribute}_html=", redacted_data[:document].to_html.html_safe)
        object.user_visible_reference_count = redacted_data[:visible_reference_count]
      end
    end

    # Renders the attribute of every given object.
    def render_objects(objects, attribute)
      render_attributes(objects, attribute)
    end

    # Redacts the list of documents.
    #
    # Returns an Array containing the redacted documents.
    def redact_documents(documents)
      redactor = Redactor.new(project, user)

      redactor.redact(documents)
    end

    # Returns a Banzai context for the given object and attribute.
    def context_for(object, attribute)
      context = base_context.merge(cache_key: [object, attribute])

      if object.respond_to?(:author)
        context[:author] = object.author
      end

      context
    end

    # Renders the attributes of a set of objects.
    #
    # Returns an Array of `Nokogiri::HTML::Document`.
    def render_attributes(objects, attribute)
      strings_and_contexts = objects.map do |object|
        context = context_for(object, attribute)

        string = object.__send__(attribute)

        { text: string, context: context }
      end

      Banzai.cache_collection_render(strings_and_contexts).each_with_index.map do |html, index|
        Banzai::Pipeline[:relative_link].to_document(html, strings_and_contexts[index][:context])
      end
    end

    def base_context
      @base_context ||= @raw_context.merge(current_user: user, project: project)
    end
  end
end
