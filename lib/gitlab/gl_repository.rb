# frozen_string_literal: true

module Gitlab
  class GlRepository
    include Singleton

    # TODO: Refactor these constants into proper classes
    # https://gitlab.com/gitlab-org/gitlab/-/issues/259008
    PROJECT = RepoType.new(
      name: :project,
      access_checker_class: Gitlab::GitAccessProject,
      repository_resolver: -> (project) { ::Repository.new(project.full_path, project, shard: project.repository_storage, disk_path: project.disk_path) }
    ).freeze
    WIKI = RepoType.new(
      name: :wiki,
      access_checker_class: Gitlab::GitAccessWiki,
      repository_resolver: -> (container) do
        wiki = container.is_a?(Wiki) ? container : container.wiki # Also allow passing a Project, Group, or Geo::DeletedProject
        ::Repository.new(wiki.full_path, wiki, shard: wiki.repository_storage, disk_path: wiki.disk_path, repo_type: WIKI)
      end,
      container_class: ProjectWiki,
      project_resolver: -> (wiki) { wiki.try(:project) },
      guest_read_ability: :download_wiki_code,
      suffix: :wiki
    ).freeze
    SNIPPET = RepoType.new(
      name: :snippet,
      access_checker_class: Gitlab::GitAccessSnippet,
      repository_resolver: -> (snippet) { ::Repository.new(snippet.full_path, snippet, shard: snippet.repository_storage, disk_path: snippet.disk_path, repo_type: SNIPPET) },
      container_class: Snippet,
      project_resolver: -> (snippet) { snippet&.project },
      guest_read_ability: :read_snippet
    ).freeze
    DESIGN = ::Gitlab::GlRepository::RepoType.new(
      name: :design,
      access_checker_class: ::Gitlab::GitAccessDesign,
      repository_resolver: -> (project) { project.design_management_repository.repository },
      suffix: :design,
      container_class: DesignManagement::Repository
    ).freeze

    TYPES = {
      PROJECT.name.to_s => PROJECT,
      WIKI.name.to_s => WIKI,
      SNIPPET.name.to_s => SNIPPET,
      DESIGN.name.to_s => DESIGN
    }.freeze

    def self.types
      instance.types
    end

    def self.parse(gl_repository)
      identifier = ::Gitlab::GlRepository::Identifier.parse(gl_repository)

      repo_type = identifier.repo_type
      container = identifier.container

      [container, repo_type.project_for(container), repo_type]
    end

    def self.default_type
      PROJECT
    end

    def types
      TYPES
    end

    private_class_method :instance
  end
end
