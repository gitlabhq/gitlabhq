# frozen_string_literal: true

module Evidences
  class ReleaseEntity < Grape::Entity
    expose :id
    expose :tag, as: :tag_name
    expose :name
    expose :description
    expose :created_at
    expose :project, using: Evidences::ProjectEntity
    expose :milestones, using: Evidences::MilestoneEntity
    expose :packages, using: Evidences::PackageEntity do |release, _options|
      release.tagged_packages
    end
  end
end

Evidences::ReleaseEntity.prepend_mod_with('Evidences::ReleaseEntity')
