module MarkdownPreview
  private

  def render_markdown_preview(text, markdown_context = {})
    render json: {
      body: view_context.markdown(text, markdown_context),
      references: {
        users: preview_referenced_users(text)
      }
    }
  end

  def preview_referenced_users(text)
    extractor = Gitlab::ReferenceExtractor.new(@project, current_user)
    extractor.analyze(text, author: current_user)

    extractor.users.map(&:username)
  end
end
