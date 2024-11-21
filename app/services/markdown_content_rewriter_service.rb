# frozen_string_literal: true

# This service passes Markdown content through our GFM rewriter classes
# which rewrite references to GitLab objects and uploads within the content
# based on their visibility by the `target_parent`.
class MarkdownContentRewriterService
  include Gitlab::Utils::StrongMemoize

  REWRITERS = [Gitlab::Gfm::ReferenceRewriter, Gitlab::Gfm::UploadsRewriter].freeze

  def initialize(current_user, object, field, source_parent, target_parent)
    @current_user = current_user
    @source_parent = source_parent
    @target_parent = target_parent
    @object = object
    @field = field

    validate_parameters!

    @content = object[field].dup.presence
    @html_field = object.cached_markdown_fields.html_field(field)
    @content_html = object.cached_html_for(field)

    @rewriters =
      REWRITERS.map do |rewriter_class|
        rewriter_class.new(@content, content_html, source_parent, current_user)
      end

    @result = {
      field => nil,
      html_field => nil
    }.with_indifferent_access
  end

  def execute
    return result unless content

    unless safe_to_copy_markdown?
      rewriters.each do |rewriter|
        rewriter.rewrite(target_parent)
      end
    end

    result[field] = content
    result[html_field] = content_html if safe_to_copy_markdown?
    result[:skip_markdown_cache_validation] = safe_to_copy_markdown?

    result
  end

  def safe_to_copy_markdown?
    strong_memoize(:safe_to_copy_markdown) do
      rewriters.none?(&:needs_rewrite?)
    end
  end

  private

  def validate_parameters!
    if object.cached_markdown_fields[field].nil?
      raise ArgumentError, 'The `field` attribute does not contain cached markdown'
    end
  end

  attr_reader :current_user, :content, :source_parent,
    :target_parent, :rewriters, :content_html,
    :field, :html_field, :object, :result
end
