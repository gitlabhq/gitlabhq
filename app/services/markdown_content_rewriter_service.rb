# frozen_string_literal: true

# This service passes Markdown content through our GFM rewriter classes
# which rewrite references to GitLab objects and uploads within the content
# based on their visibility by the `target_parent`.
class MarkdownContentRewriterService
  REWRITERS = [Gitlab::Gfm::ReferenceRewriter, Gitlab::Gfm::UploadsRewriter].freeze

  def initialize(current_user, content, source_parent, target_parent)
    # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/39654#note_399095117
    raise ArgumentError, 'The rewriter classes require that `source_parent` is a `Project`' \
      unless source_parent.is_a?(Project)

    @current_user = current_user
    @content = content.presence
    @source_parent = source_parent
    @target_parent = target_parent
  end

  def execute
    return unless content

    REWRITERS.inject(content) do |text, klass|
      rewriter = klass.new(text, source_parent, current_user)
      rewriter.rewrite(target_parent)
    end
  end

  private

  attr_reader :current_user, :content, :source_parent, :target_parent
end
