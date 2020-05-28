# frozen_string_literal: true

module Gitlab
  class GlRepository
    include Singleton

    PROJECT = RepoType.new(
      name: :project,
      access_checker_class: Gitlab::GitAccess,
      repository_resolver: -> (project) { project&.repository }
    ).freeze
    WIKI = RepoType.new(
      name: :wiki,
      access_checker_class: Gitlab::GitAccessWiki,
      repository_resolver: -> (project) { project&.wiki&.repository },
      suffix: :wiki
    ).freeze
    SNIPPET = RepoType.new(
      name: :snippet,
      access_checker_class: Gitlab::GitAccessSnippet,
      repository_resolver: -> (snippet) { snippet&.repository },
      container_resolver: -> (id) { Snippet.find_by_id(id) },
      project_resolver: -> (snippet) { snippet&.project },
      guest_read_ability: :read_snippet
    ).freeze
    DESIGN = ::Gitlab::GlRepository::RepoType.new(
      name: :design,
      access_checker_class: ::Gitlab::GitAccessDesign,
      repository_resolver: -> (project) { ::DesignManagement::Repository.new(project) },
      suffix: :design
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
      type_name, _id = gl_repository.split('-').first
      type = types[type_name]

      unless type
        raise ArgumentError, "Invalid GL Repository \"#{gl_repository}\""
      end

      container = type.fetch_container!(gl_repository)

      [container, type.project_for(container), type]
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
