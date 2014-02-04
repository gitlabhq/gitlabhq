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

    gfm_body = gfm(escaped_body, html_options)

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
                            hard_wrap: true,
                            safe_links_only: true
                          }.merge(options))
      @markdown = Redcarpet::Markdown.new(gitlab_renderer,
                      # see https://github.com/vmg/redcarpet#and-its-like-really-simple-to-use
                      no_intra_emphasis: true,
                      tables: true,
                      fenced_code_blocks: true,
                      autolink: true,
                      strikethrough: true,
                      lax_html_blocks: true,
                      space_after_headers: true,
                      superscript: true)
    end
    @markdown.render(text).html_safe
  end

  def render_wiki_content(wiki_page)
    if wiki_page.format == :markdown
      markdown(wiki_page.content)
    else
      wiki_page.formatted_content.html_safe
    end
  end

  # text - whole text from a markdown file
  # project_path_with_namespace - namespace/projectname, eg. gitlabhq/gitlabhq
  # ref - name of the branch or reference, eg. stable
  # requested_path - path of request, eg. doc/api/README.md, used in special case when path is pointing to the .md file were the original request is coming from
  # wiki - whether the markdown is from wiki or not
  def create_relative_links(text, project, ref, requested_path, wiki = false)
    @path_to_satellite = project.satellite.path
    project_path_with_namespace = project.path_with_namespace
    paths = extract_paths(text)
    paths.each do |file_path|
      original_file_path = extract(file_path)
      new_path = rebuild_path(project_path_with_namespace, original_file_path, requested_path, ref)
      if reference_path?(file_path)
        # Replacing old string with a new one that contains updated path
        # eg. [some document]: document.md will be replaced with [some document] /namespace/project/master/blob/document.md
        text.gsub!(file_path, file_path.gsub(original_file_path, "/#{new_path}"))
      else
        # Replacing old string with a new one with brackets ]() to prevent replacing occurence of a word
        # e.g. If we have a markdown like [test](test) this will replace ](test) and not the word test
        text.gsub!("](#{file_path})", "](/#{new_path})")
      end
    end
    text
  end

  def extract_paths(markdown_text)
    all_markdown_paths = pick_out_paths(markdown_text)
    paths = remove_empty(all_markdown_paths)
    select_relative(paths)
  end

  # Split the markdown text to each line and find all paths, this will match anything with - ]("some_text") and [some text]: file.md
  def pick_out_paths(markdown_text)
    inline_paths = markdown_text.split("\n").map { |text| text.scan(/\]\(([^(]+)\)/) }
    reference_paths = markdown_text.split("\n").map { |text| text.scan(/\[.*\]:.*/) }
    inline_paths + reference_paths
  end

  # Removes any empty result produced by not matching the regexp
  def remove_empty(paths)
    paths.reject{|l| l.empty? }.flatten
  end

  # If a path is a reference style link we need to omit ]:
  def extract(path)
    path.split("]: ").last
  end

  # Reject any path that contains ignored protocol
  # eg. reject "https://gitlab.org} but accept "doc/api/README.md"
  def select_relative(paths)
    paths.reject{|path| ignored_protocols.map{|protocol| path.include?(protocol)}.any?}
  end

  # Check whether a path is a reference-style link
  def reference_path?(path)
    path.include?("]: ")
  end

  def ignored_protocols
    ["http://","https://", "ftp://", "mailto:"]
  end

  def rebuild_path(path_with_namespace, path, requested_path, ref)
    file_path = relative_file_path(path, requested_path)
    [
      path_with_namespace,
      path_with_ref(file_path, ref),
      file_path
    ].compact.join("/")
  end

  # Checks if the path exists in the repo
  # eg. checks if doc/README.md exists, if it doesn't then it is a wiki link
  def path_with_ref(path, ref)
    if file_exists?(path)
      "#{local_path(path)}/#{correct_ref(ref)}"
    else
      "wikis"
    end
  end

  def relative_file_path(path, requested_path)
    nested_path = build_nested_path(path, requested_path)
    return nested_path if file_exists?(nested_path)
    path
  end

  # Covering a special case, when the link is referencing file in the same directory eg:
  # If we are at doc/api/README.md and the README.md contains relative links like [Users](users.md)
  # this takes the request path(doc/api/README.md), and replaces the README.md with users.md so the path looks like doc/api/users.md
  # If we are at doc/api and the README.md shown in below the tree view
  # this takes the rquest path(doc/api) and adds users.md so the path looks like doc/api/users.md
  def build_nested_path(path, request_path)
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

  def file_exists?(path)
    return false if path.nil? || path.empty?
    return @repository.blob_at(current_sha, path).present? || @repository.tree(current_sha, path).entries.any?
  end

  # Check if the path is pointing to a directory(tree) or a file(blob)
  # eg. doc/api is directory and doc/README.md is file
  def local_path(path)
    return "tree" if @repository.tree(current_sha, path).entries.any?
    return "raw" if @repository.blob_at(current_sha, path).image?
    return "blob"
  end

  def current_ref
    @commit.nil? ? "master" : @commit.id
  end

  def current_sha
    if @commit
      @commit.id
    else
      @repository.head_commit.sha
    end
  end

  # We will assume that if no ref exists we can point to master
  def correct_ref(ref)
    ref ? ref : "master"
  end
end
