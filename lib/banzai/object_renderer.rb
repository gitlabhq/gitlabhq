module Banzai
  # Class for rendering multiple objects (e.g. Note instances) in a single pass,
  # using +render_field+ to benefit from caching in the database. Rendering and
  # redaction are both performed.
  #
  # The unredacted HTML is generated according to the usual +render_field+
  # policy, so specify the pipeline and any other context options on the model.
  #
  # The *redacted* (i.e., suitable for use) HTML is placed in an attribute
  # named "redacted_<foo>", where <foo> is the name of the cache field for the
  # chosen attribute.
  #
  # As an example, rendering the attribute `note` would place the unredacted
  # HTML into `note_html` and the redacted HTML into `redacted_note_html`.
  class ObjectRenderer
    attr_reader :project, :user

    # project - A Project to use for redacting Markdown.
    # user - The user viewing the Markdown/HTML documents, if any.
    # context - A Hash containing extra attributes to use during redaction
    def initialize(project, user = nil, redaction_context = {})
      @project = project
      @user = user
      @redaction_context = redaction_context
    end

    # Renders and redacts an Array of objects.
    #
    # objects - The objects to render.
    # attribute - The attribute containing the raw Markdown to render.
    #
    # Returns the same input objects.
    def render(objects, attribute)
      documents = render_objects(objects, attribute)
      redacted = redact_documents(documents)

      objects.each_with_index do |object, index|
        redacted_data = redacted[index]
        object.__send__("redacted_#{attribute}_html=", redacted_data[:document].to_html.html_safe)
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
      context = base_context.dup
      context = context.merge(object.banzai_render_context(attribute))
      context
    end

    # Renders the attributes of a set of objects.
    #
    # Returns an Array of `Nokogiri::HTML::Document`.
    def render_attributes(objects, attribute)
      objects.map do |object|
        string = Banzai.render_field(object, attribute)
        context = context_for(object, attribute)

        Banzai::Pipeline[:relative_link].to_document(string, context)
      end
    end

    def base_context
      @base_context ||= @redaction_context.merge(current_user: user, project: project)
    end
  end
end
