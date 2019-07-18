# frozen_string_literal: true

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
    attr_reader :context

    # default_project - A default Project to use for redacting Markdown.
    # user - The user viewing the Markdown/HTML documents, if any.
    # redaction_context - A Hash containing extra attributes to use during redaction
    def initialize(default_project: nil, user: nil, redaction_context: {})
      @context = RenderContext.new(default_project, user)
      @redaction_context = base_context.merge(redaction_context)
    end

    # Renders and redacts an Array of objects.
    #
    # objects - The objects to render.
    # attribute - The attribute containing the raw Markdown to render.
    #
    # Returns the same input objects.
    def render(objects, attribute)
      documents = render_documents(objects, attribute)
      documents = post_process_documents(documents, objects, attribute)
      redacted = redact_documents(documents)

      objects.each_with_index do |object, index|
        redacted_data = redacted[index]
        object.__send__("redacted_#{attribute}_html=", redacted_data[:document].to_html(save_options).html_safe) # rubocop:disable GitlabSecurity/PublicSend
        object.user_visible_reference_count = redacted_data[:visible_reference_count] if object.respond_to?(:user_visible_reference_count)
        object.total_reference_count = redacted_data[:total_reference_count] if object.respond_to?(:total_reference_count)
      end
    end

    private

    def render_documents(objects, attribute)
      pipeline = HTML::Pipeline.new([])

      objects.map do |object|
        document = pipeline.to_document(Banzai.render_field(object, attribute))

        context.associate_document(document, object)

        document
      end
    end

    def post_process_documents(documents, objects, attribute)
      # Called here to populate cache, refer to IssuableExtractor docs
      IssuableExtractor.new(context).extract(documents)

      documents.zip(objects).map do |document, object|
        pipeline_context = context_for(document, object, attribute)
        Banzai::Pipeline[:post_process].to_document(document, pipeline_context)
      end
    end

    # Redacts the list of documents.
    #
    # Returns an Array containing the redacted documents.
    def redact_documents(documents)
      redactor = ReferenceRedactor.new(context)

      redactor.redact(documents)
    end

    # Returns a Banzai context for the given object and attribute.
    def context_for(document, object, attribute)
      @redaction_context.merge(object.banzai_render_context(attribute)).merge(
        project: context.project_for_node(document)
      )
    end

    def base_context
      {
        current_user: context.current_user,
        skip_redaction: true
      }
    end

    def save_options
      return {} unless @redaction_context[:xhtml]

      { save_with: Nokogiri::XML::Node::SaveOptions::AS_XHTML }
    end
  end
end
