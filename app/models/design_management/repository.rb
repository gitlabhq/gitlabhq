# frozen_string_literal: true

module DesignManagement
  class Repository < ::Repository
    extend ::Gitlab::Utils::Override

    # We define static git attributes for the design repository as this
    # repository is entirely GitLab-managed rather than user-facing.
    #
    # Enable all uploaded files to be stored in LFS.
    MANAGED_GIT_ATTRIBUTES = <<~GA
      /#{DesignManagement.designs_directory}/* filter=lfs diff=lfs merge=lfs -text
    GA

    def initialize(project)
      full_path = project.full_path + Gitlab::GlRepository::DESIGN.path_suffix
      disk_path = project.disk_path + Gitlab::GlRepository::DESIGN.path_suffix

      super(full_path, project, shard: project.repository_storage, disk_path: disk_path, repo_type: Gitlab::GlRepository::DESIGN)
    end

    # Override of a method called on Repository instances but sent via
    # method_missing to Gitlab::Git::Repository where it is defined
    def info_attributes
      @info_attributes ||= Gitlab::Git::AttributesParser.new(MANAGED_GIT_ATTRIBUTES)
    end

    # Override of a method called on Repository instances but sent via
    # method_missing to Gitlab::Git::Repository where it is defined
    def attributes(path)
      info_attributes.attributes(path)
    end

    # Override of a method called on Repository instances but sent via
    # method_missing to Gitlab::Git::Repository where it is defined
    def gitattribute(path, name)
      attributes(path)[name]
    end

    # Override of a method called on Repository instances but sent via
    # method_missing to Gitlab::Git::Repository where it is defined
    def attributes_at(_ref = nil)
      info_attributes
    end

    override :copy_gitattributes
    def copy_gitattributes(_ref = nil)
      true
    end
  end
end
