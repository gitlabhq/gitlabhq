module GitlabMarkdownHelper
  include Gitlab::Markdown

  # Use this in places where you would normally use link_to(gfm(...), ...).
  #
  # It solves a problem occurring with nested links (i.e.
  # "<a>outer text <a>gfm ref</a> more outer text</a>"). This will not be
  # interpreted as intended. Browsers will parse something like
  # "<a>outer text </a><a>gfm ref</a> more outer text" (notice the last part is
  # not linked any more). link_to_gfm corrects that. It wraps all parts to
  # explicitly produce the correct linking behavior (i.e.
  # "<a>outer text </a><a>gfm ref</a><a> more outer text</a>").
  def link_to_gfm(body, url, html_options = {})
    return "" if body.blank?

    escaped_body = if body =~ /^\<img/
                     body
                   else
                     escape_once(body)
                   end

    gfm_body = gfm(escaped_body, @project, html_options)

    gfm_body.gsub!(%r{<a.*?>.*?</a>}m) do |match|
      "</a>#{match}#{link_to("", url, html_options)[0..-5]}" # "</a>".length +1
    end

    link_to(gfm_body.html_safe, url, html_options)
  end

  def markdown(text, options={})
    unless (@markdown and options == @options)
      @options = options
      gitlab_renderer = Redcarpet::Render::GitlabHTML.new(self, {
                            # see https://github.com/vmg/redcarpet#darling-i-packed-you-a-couple-renderers-for-lunch-
                            filter_html: true,
                            with_toc_data: true,
                            safe_links_only: true
                          }.merge(options))
      @markdown = Redcarpet::Markdown.new(gitlab_renderer,
                      # see https://github.com/vmg/redcarpet#and-its-like-really-simple-to-use
                      no_intra_emphasis: true,
                      tables: true,
                      fenced_code_blocks: true,
                      autolink: true,
                      strikethrough: true,
                      lax_spacing: true,
                      space_after_headers: true,
                      superscript: true)
    end
    @markdown.render(text).html_safe
  end

  # Return the first line of +text+, up to +max_chars+, after parsing the line
  # as Markdown.  HTML tags in the parsed output are not counted toward the
  # +max_chars+ limit.  If the length limit falls within a tag's contents, then
  # the tag contents are truncated without removing the closing tag.
  def first_line_in_markdown(text, max_chars = nil)
    md = markdown(text).strip

    truncate_visible(md, max_chars || md.length) if md.present?
  end

  def render_wiki_content(wiki_page)
    if wiki_page.format == :markdown
      markdown(wiki_page.content)
    else
      wiki_page.formatted_content.html_safe
    end
  end

  def create_relative_links(text)
    paths = extract_paths(text)

    paths.uniq.each do |file_path|
      # If project does not have repository
      # its nothing to rebuild
      #
      # TODO: pass project variable to markdown helper instead of using
      # instance variable. Right now it generates invalid path for pages out
      # of project scope. Example: search results where can be rendered markdown
      # from different projects
      if @repository && @repository.exists? && !@repository.empty?
        new_path = rebuild_path(file_path)
        # Finds quoted path so we don't replace other mentions of the string
        # eg. "doc/api" will be replaced and "/home/doc/api/text" won't
        text.gsub!("\"#{file_path}\"", "\"/#{new_path}\"")
      end
    end

    text
  end

  def extract_paths(text)
    links = substitute_links(text)
    image_links = substitute_image_links(text)
    links + image_links
  end

  def substitute_links(text)
    links = text.scan(/<a href=\"([^"]*)\">/)
    relative_links = links.flatten.reject{ |link| link_to_ignore? link }
    relative_links
  end

  def substitute_image_links(text)
    links = text.scan(/<img src=\"([^"]*)\"/)
    relative_links = links.flatten.reject{ |link| link_to_ignore? link }
    relative_links
  end

  def link_to_ignore?(link)
    if link =~ /\#\w+/
      # ignore anchors like <a href="#my-header">
      true
    else
      ignored_protocols.map{ |protocol| link.include?(protocol) }.any?
    end
  end

  def ignored_protocols
    ["http://","https://", "ftp://", "mailto:"]
  end

  def rebuild_path(path)
    path.gsub!(/(#.*)/, "")
    id = $1 || ""
    file_path = relative_file_path(path)
    file_path = sanitize_slashes(file_path)

    [
      Gitlab.config.gitlab.relative_url_root,
      @project.path_with_namespace,
      path_with_ref(file_path),
      file_path
    ].compact.join("/").gsub(/^\/*|\/*$/, '') + id
  end

  def sanitize_slashes(path)
    path[0] = "" if path.start_with?("/")
    path.chop if path.end_with?("/")
    path
  end

  def relative_file_path(path)
    requested_path = @path
    nested_path = build_nested_path(path, requested_path)
    return nested_path if file_exists?(nested_path)
    path
  end

  # Covering a special case, when the link is referencing file in the same directory eg:
  # If we are at doc/api/README.md and the README.md contains relative links like [Users](users.md)
  # this takes the request path(doc/api/README.md), and replaces the README.md with users.md so the path looks like doc/api/users.md
  # If we are at doc/api and the README.md shown in below the tree view
  # this takes the request path(doc/api) and adds users.md so the path looks like doc/api/users.md
  def build_nested_path(path, request_path)
    return request_path if path == ""
    return path unless request_path
    if local_path(request_path) == "tree"
      base = request_path.split("/").push(path)
      base.join("/")
    else
      base = request_path.split("/")
      base.pop
      base.push(path).join("/")
    end
  end

  # Checks if the path exists in the repo
  # eg. checks if doc/README.md exists, if not then link to blob
  def path_with_ref(path)
    if file_exists?(path)
      "#{local_path(path)}/#{correct_ref}"
    else
      "blob/#{correct_ref}"
    end
  end

  def file_exists?(path)
    return false if path.nil?
    return @repository.blob_at(current_sha, path).present? || @repository.tree(current_sha, path).entries.any?
  end

  # Check if the path is pointing to a directory(tree) or a file(blob)
  # eg. doc/api is directory and doc/README.md is file
  def local_path(path)
    return "tree" if @repository.tree(current_sha, path).entries.any?
    return "raw" if @repository.blob_at(current_sha, path).image?
    return "blob"
  end

  def current_sha
    if @commit
      @commit.id
    elsif @repository && !@repository.empty?
      if @ref
        @repository.commit(@ref).try(:sha)
      else
        @repository.head_commit.sha
      end
    end
  end

  # We will assume that if no ref exists we can point to master
  def correct_ref
    @ref ? @ref : "master"
  end

  private

  # Return +text+, truncated to +max_chars+ characters, excluding any HTML
  # tags.
  def truncate_visible(text, max_chars)
    doc = Nokogiri::HTML.fragment(text)
    content_length = 0
    truncated = false

    doc.traverse do |node|
      if node.text? || node.content.empty?
        if truncated
          node.remove
          next
        end

        # Handle line breaks within a node
        if node.content.strip.lines.length > 1
          node.content = "#{node.content.lines.first.chomp}..."
          truncated = true
        end

        num_remaining = max_chars - content_length
        if node.content.length > num_remaining
          node.content = node.content.truncate(num_remaining)
          truncated = true
        end
        content_length += node.content.length
      end

      truncated = truncate_if_block(node, truncated)
    end

    doc.to_html
  end

  # Used by #truncate_visible.  If +node+ is the first block element, and the
  # text hasn't already been truncated, then append "..." to the node contents
  # and return true.  Otherwise return false.
  def truncate_if_block(node, truncated)
    if node.element? && node.description.block? && !truncated
      node.content = "#{node.content}..." if node.next_sibling
      true
    else
      truncated
    end
  end

  def cross_project_reference(project, entity)
    path = project.path_with_namespace

    if entity.kind_of?(Issue)
      [path, entity.iid].join('#')
    elsif entity.kind_of?(MergeRequest)
      [path, entity.iid].join('!')
    else
      raise 'Not supported type'
    end
  end
end
