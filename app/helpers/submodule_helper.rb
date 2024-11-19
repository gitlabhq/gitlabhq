# frozen_string_literal: true

module SubmoduleHelper
  extend self

  VALID_SUBMODULE_PROTOCOLS = %w[http https git ssh].freeze

  # links to files listing for submodule if submodule is a project on this server
  def submodule_links(submodule_item, ref = nil, repository = @repository, diff_file = nil)
    repository.submodule_links.for(submodule_item, ref, diff_file)
  end

  def submodule_links_for_url(submodule_item_id, url, repository, old_submodule_item_id = nil)
    return [nil, nil, nil] unless url

    if url == '.' || url == './'
      url = File.join(Gitlab.config.gitlab.url, repository.project.full_path)
    end

    namespace, project = extract_namespace_project(url)

    if namespace.blank? || project.blank?
      return [sanitize_submodule_url(url), nil, nil]
    end

    if self_url?(url, namespace, project)
      [
        url_helpers.namespace_project_path(namespace, project),
        url_helpers.namespace_project_tree_path(namespace, project, submodule_item_id),
        (

          if old_submodule_item_id
            url_helpers.namespace_project_compare_path(
              namespace, project,
              to: submodule_item_id,
              from: old_submodule_item_id
            )
          end

        )
      ]
    elsif relative_self_url?(url)
      relative_self_links(url, submodule_item_id, old_submodule_item_id, repository.project)
    elsif gist_github_dot_com_url?(url)
      gist_github_com_tree_links(namespace, project, submodule_item_id)
    elsif github_dot_com_url?(url)
      github_com_tree_links(namespace, project, submodule_item_id, old_submodule_item_id)
    elsif gitlab_dot_com_url?(url)
      gitlab_com_tree_links(namespace, project, submodule_item_id, old_submodule_item_id)
    else
      [sanitize_submodule_url(url), nil, nil]
    end
  end

  protected

  def extract_namespace_project(url)
    namespace_fragment, _, project = url.rpartition('/')
    namespace = namespace_fragment.rpartition(%r{[:/]}).last

    return [nil, nil] unless project.present? && namespace.present?

    gitlab_hosts = [Gitlab.config.gitlab.url,
      Gitlab.config.gitlab_shell.ssh_path_prefix]

    matching_host = gitlab_hosts.find do |host|
      url.start_with?(host)
    end

    if matching_host
      namespace, _, project = url.delete_prefix(matching_host).rpartition('/')
    end

    namespace.delete_prefix!('/')
    project.rstrip!
    project.delete_suffix!('.git')

    [namespace, project]
  end

  def gist_github_dot_com_url?(url)
    url =~ %r{gist\.github\.com[/:][^/]+/[^/]+\Z}
  end

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

    url_with_dotgit = "#{url_no_dotgit}.git"
    url_with_dotgit == Gitlab::RepositoryUrlBuilder.build([namespace, '/', project].join(''))
  end

  def relative_self_url?(url)
    url.start_with?('../', './')
  end

  def gitlab_com_tree_links(namespace, project, commit, old_commit)
    base = ['https://gitlab.com/', namespace, '/', project].join('')
    [
      base,
      [base, '/-/tree/', commit].join(''),
      ([base, '/-/compare/', old_commit, '...', commit].join('') if old_commit)
    ]
  end

  def gist_github_com_tree_links(namespace, project, commit)
    base = ['https://gist.github.com/', namespace, '/', project].join('')
    [base, [base, commit].join('/'), nil]
  end

  def github_com_tree_links(namespace, project, commit, old_commit)
    base = ['https://github.com/', namespace, '/', project].join('')
    [
      base,
      [base, '/tree/', commit].join(''),
      ([base, '/compare/', old_commit, '...', commit].join('') if old_commit)
    ]
  end

  def relative_self_links(relative_path, commit, old_commit, project)
    relative_path = relative_path.rstrip
    absolute_project_path = "/#{project.full_path}"

    # Resolve `relative_path` to target path
    # Assuming `absolute_project_path` is `/g1/p1`:
    # ../p2.git -> /g1/p2
    # ../g2/p3.git -> /g1/g2/p3
    # ../../g3/g4/p4.git -> /g3/g4/p4
    submodule_project_path = File.absolute_path(relative_path, absolute_project_path)
    target_namespace_path = File.dirname(submodule_project_path)

    if target_namespace_path == '/' || target_namespace_path.start_with?(absolute_project_path)
      return [nil, nil, nil]
    end

    target_namespace_path.sub!(%r{^/}, '')
    submodule_base = File.basename(submodule_project_path, '.git')

    begin
      [
        url_helpers.namespace_project_path(target_namespace_path, submodule_base),
        url_helpers.namespace_project_tree_path(target_namespace_path, submodule_base, commit),

        (if old_commit
           url_helpers.namespace_project_compare_path(
             target_namespace_path, submodule_base, to: commit, from: old_commit
           )
         end)

      ]
    rescue ActionController::UrlGenerationError
      [nil, nil, nil]
    end
  end

  def sanitize_submodule_url(url)
    uri = URI.parse(url)

    if uri.scheme.in?(VALID_SUBMODULE_PROTOCOLS)
      uri.to_s
    end
  rescue URI::InvalidURIError
    nil
  end

  def url_helpers
    Gitlab::Routing.url_helpers
  end
end
