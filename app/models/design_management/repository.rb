# frozen_string_literal: true

module DesignManagement
  class Repository < ApplicationRecord
    include ::Gitlab::Utils::StrongMemoize
    include HasRepository

    belongs_to :project, inverse_of: :design_management_repository
    validates :project, presence: true, uniqueness: true

    delegate :lfs_enabled?, :storage, :repository_storage, :run_after_commit, to: :project

    def repository
      DesignManagement::GitRepository.new(
        full_path,
        self,
        shard: repository_storage,
        disk_path: disk_path,
        repo_type: repo_type
      )
    end
    strong_memoize_attr :repository

    def full_path
      project.full_path + repo_type.path_suffix
    end

    def disk_path
      project.disk_path + repo_type.path_suffix
    end

    def repo_type
      Gitlab::GlRepository::DESIGN
    end
  end
end

DesignManagement::Repository.prepend_mod_with('DesignManagement::Repository')
