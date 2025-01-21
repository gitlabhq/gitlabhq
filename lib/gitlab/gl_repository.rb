# frozen_string_literal: true

module Gitlab
  class GlRepository
    include Singleton

    PROJECT = Gitlab::Repositories::ProjectRepository.instance
    WIKI = Gitlab::Repositories::WikiRepository.instance
    SNIPPET = Gitlab::Repositories::SnippetRepository.instance
    DESIGN = ::Gitlab::Repositories::DesignManagementRepository.instance

    TYPES = {
      PROJECT.type_id => PROJECT,
      WIKI.type_id => WIKI,
      SNIPPET.type_id => SNIPPET,
      DESIGN.type_id => DESIGN
    }.freeze

    def self.types
      instance.types
    end

    def self.parse(gl_repository)
      identifier = ::Gitlab::Repositories::Identifier.parse(gl_repository)

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
