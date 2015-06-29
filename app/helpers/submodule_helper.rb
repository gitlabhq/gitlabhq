module SubmoduleHelper
  include Gitlab::ShellAdapter

  # links to files listing for submodule if submodule is a project on this server
  def submodule_links(submodule_item, ref = nil, repository = @repository)
    url = repository.submodule_url_for(ref, submodule_item.path)

    return url, nil unless url =~ /([^\/:]+)\/([^\/]+\.git)\Z/

    namespace = $1
    project = $2
    project.chomp!('.git')

    if self_url?(url, namespace, project)
      return namespace_project_path(namespace, project),
        namespace_project_tree_path(namespace, project,
                                    submodule_item.id)
    elsif relative_self_url?(url)
      relative_self_links(url, submodule_item.id)
    elsif github_dot_com_url?(url)
      standard_links('github.com', namespace, project, submodule_item.id)
    elsif gitlab_dot_com_url?(url)
      standard_links('gitlab.com', namespace, project, submodule_item.id)
    else
      return url, nil
    end
  end

  protected

  def github_dot_com_url?(url)
    url =~ /github\.com[\/:][^\/]+\/[^\/]+\Z/
  end

  def gitlab_dot_com_url?(url)
    url =~ /gitlab\.com[\/:][^\/]+\/[^\/]+\Z/
  end

  def self_url?(url, namespace, project)
    return true if url == [ Gitlab.config.gitlab.url, '/', namespace, '/',
                            project, '.git' ].join('')
    url == gitlab_shell.url_to_repo([namespace, '/', project].join(''))
  end

  def relative_self_url?(url)
    # (./)?(../repo.git) || (./)?(../../project/repo.git) )
    url =~ /\A((\.\/)?(\.\.\/))(?!(\.\.)|(.*\/)).*\.git\z/ || url =~ /\A((\.\/)?(\.\.\/){2})(?!(\.\.))([^\/]*)\/(?!(\.\.)|(.*\/)).*\.git\z/
  end

  def standard_links(host, namespace, project, commit)
    base = [ 'https://', host, '/', namespace, '/', project ].join('')
    [base, [ base, '/tree/', commit ].join('')]
  end

  def relative_self_links(url, commit)
    # Map relative links to a namespace and project
    # For example:
    # ../bar.git -> same namespace, repo bar
    # ../foo/bar.git -> namespace foo, repo bar
    # ../../foo/bar/baz.git -> namespace bar, repo baz
    components = url.split('/')
    base = components.pop.gsub(/.git$/, '')
    namespace = components.pop.gsub(/^\.\.$/, '')

    if namespace.empty?
      namespace = @project.namespace.path
    end

    [
      namespace_project_path(namespace, base),
      namespace_project_tree_path(namespace, base, commit)
    ]
  end
end
