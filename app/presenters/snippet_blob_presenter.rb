# frozen_string_literal: true

class SnippetBlobPresenter < BlobPresenter
  def rich_data
    return if blob.binary?
    return unless blob.rich_viewer

    render_rich_partial
  end

  def plain_data
    return if blob.binary?

    highlight(plain: false)
  end

  def raw_path
    if snippet.is_a?(ProjectSnippet)
      raw_project_snippet_path(snippet.project, snippet)
    else
      raw_snippet_path(snippet)
    end
  end

  private

  def snippet
    blob.container
  end

  def language
    nil
  end

  def render_rich_partial
    renderer.render("projects/blob/viewers/_#{blob.rich_viewer.partial_name}",
                    locals: { viewer: blob.rich_viewer, blob: blob, blob_raw_path: raw_path },
                    layout: false)
  end

  def renderer
    proxy = Warden::Proxy.new({}, Warden::Manager.new({})).tap do |proxy_instance|
      proxy_instance.set_user(current_user, scope: :user)
    end

    ApplicationController.renderer.new('warden' => proxy)
  end
end
