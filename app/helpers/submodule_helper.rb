module SubmoduleHelper
  include Gitlab::ShellAdapter

  # links to files listing for submodule if submodule is a project on this server
  def submodule_links(submodule_item, ref = nil)
    url = @repository.submodule_url_for(ref, submodule_item.path)

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
    url =~ /^((\.\/)?(\.\.\/))(?!(\.\.)|(.*\/)).*\.git\Z/ || url =~ /^((\.\/)?(\.\.\/){2})(?!(\.\.))([^\/]*)\/(?!(\.\.)|(.*\/)).*\.git\Z/
  end

  def standard_links(host, namespace, project, commit)
    base = [ 'https://', host, '/', namespace, '/', project ].join('')
    return base, [ base, '/tree/', commit ].join('')
  end

  def relative_self_links(url, commit)
    if url.scan(/(\.\.\/)/).size == 2
      base = url[/([^\/]*\/[^\/]*)\.git/, 1]
    else
      base = [ @project.group.path, '/', url[/([^\/]*)\.git/, 1] ].join('')
    end
    return namespace_project_path(base.namespace, base),
      namespace_project_tree_path(base.namespace, base, commit)
  end
end
