# frozen_string_literal: true

module SubmoduleHelper
  extend self

  VALID_SUBMODULE_PROTOCOLS = %w[http https git ssh].freeze

  # links to files listing for submodule if submodule is a project on this server
  def submodule_links(submodule_item, ref = nil, repository = @repository)
    url = repository.submodule_url_for(ref, submodule_item.path)

    submodule_links_for_url(submodule_item.id, url, repository)
  end

  def submodule_links_for_url(submodule_item_id, url, repository)
    return [nil, nil] unless url

    if url == '.' || url == './'
      url = File.join(Gitlab.config.gitlab.url, repository.project.full_path)
    end

    if url =~ %r{([^/:]+)/([^/]+(?:\.git)?)\Z}
      namespace, project = $1, $2
      gitlab_hosts = [Gitlab.config.gitlab.url,
                      Gitlab.config.gitlab_shell.ssh_path_prefix]

      gitlab_hosts.each do |host|
        if url.start_with?(host)
          namespace, _, project = url.sub(host, '').rpartition('/')
          break
        end
      end

      namespace.sub!(%r{\A/}, '')
      project.rstrip!
      project.sub!(/\.git\z/, '')

      if self_url?(url, namespace, project)
        [url_helpers.namespace_project_path(namespace, project),
         url_helpers.namespace_project_tree_path(namespace, project, submodule_item_id)]
      elsif relative_self_url?(url)
        relative_self_links(url, submodule_item_id, repository.project)
      elsif github_dot_com_url?(url)
        standard_links('github.com', namespace, project, submodule_item_id)
      elsif gitlab_dot_com_url?(url)
        standard_links('gitlab.com', namespace, project, submodule_item_id)
      else
        [sanitize_submodule_url(url), nil]
      end
    else
      [sanitize_submodule_url(url), nil]
    end
  end

  protected

  def github_dot_com_url?(url)
    url =~ %r{github\.com[/:][^/]+/[^/]+\Z}
  end

  def gitlab_dot_com_url?(url)
    url =~ %r{gitlab\.com[/:][^/]+/[^/]+\Z}
  end

  def self_url?(url, namespace, project)
    url_no_dotgit = url.chomp('.git')
    return true if url_no_dotgit == [Gitlab.config.gitlab.url, '/', namespace, '/',
                                     project].join('')

    url_with_dotgit = url_no_dotgit + '.git'
    url_with_dotgit == Gitlab::Shell.new.url_to_repo([namespace, '/', project].join(''))
  end

  def relative_self_url?(url)
    url.start_with?('../', './')
  end

  def standard_links(host, namespace, project, commit)
    base = ['https://', host, '/', namespace, '/', project].join('')
    [base, [base, '/tree/', commit].join('')]
  end

  def relative_self_links(relative_path, commit, project)
    relative_path = relative_path.rstrip
    absolute_project_path = "/" + project.full_path

    # Resolve `relative_path` to target path
    # Assuming `absolute_project_path` is `/g1/p1`:
    # ../p2.git -> /g1/p2
    # ../g2/p3.git -> /g1/g2/p3
    # ../../g3/g4/p4.git -> /g3/g4/p4
    submodule_project_path = File.absolute_path(relative_path, absolute_project_path)
    target_namespace_path = File.dirname(submodule_project_path)

    if target_namespace_path == '/' || target_namespace_path.start_with?(absolute_project_path)
      return [nil, nil]
    end

    target_namespace_path.sub!(%r{^/}, '')
    submodule_base = File.basename(submodule_project_path, '.git')

    begin
      [
        url_helpers.namespace_project_path(target_namespace_path, submodule_base),
        url_helpers.namespace_project_tree_path(target_namespace_path, submodule_base, commit)
      ]
    rescue ActionController::UrlGenerationError
      [nil, nil]
    end
  end

  def sanitize_submodule_url(url)
    uri = URI.parse(url)

    if uri.scheme.in?(VALID_SUBMODULE_PROTOCOLS)
      uri.to_s
    else
      nil
    end
  rescue URI::InvalidURIError
    nil
  end

  def url_helpers
    Gitlab::Routing.url_helpers
  end
end
