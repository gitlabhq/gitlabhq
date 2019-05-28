# frozen_string_literal: true

module Gitlab
  class GlRepository
    include Singleton

    PROJECT = RepoType.new(
      name: :project,
      access_checker_class: Gitlab::GitAccess,
      repository_accessor: -> (project) { project.repository }
    ).freeze
    WIKI = RepoType.new(
      name: :wiki,
      access_checker_class: Gitlab::GitAccessWiki,
      repository_accessor: -> (project) { project.wiki.repository }
    ).freeze

    TYPES = {
      PROJECT.name.to_s => PROJECT,
      WIKI.name.to_s => WIKI
    }.freeze

    def self.types
      instance.types
    end

    def self.parse(gl_repository)
      type_name, _id = gl_repository.split('-').first
      type = types[type_name]
      subject_id = type&.fetch_id(gl_repository)

      unless subject_id
        raise ArgumentError, "Invalid GL Repository \"#{gl_repository}\""
      end

      project = Project.find_by_id(subject_id)

      [project, type]
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
