# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      # This class represents a CI/CD Catalog resource version.
      # Only versions which contain valid CI components are included in this table.
      class Version < ::ApplicationRecord
        include BulkInsertableAssociations
        include CacheMarkdownField
        include SemanticVersionable

        self.table_name = 'catalog_resource_versions'

        belongs_to :release, inverse_of: :catalog_resource_version
        belongs_to :catalog_resource, class_name: 'Ci::Catalog::Resource', inverse_of: :versions
        belongs_to :project, inverse_of: :catalog_resource_versions
        belongs_to :published_by, class_name: 'User'
        has_many :components, class_name: 'Ci::Catalog::Resources::Component', inverse_of: :version

        validates :release, presence: true, uniqueness: { message: N_('has already been published') }
        validates :catalog_resource, :project, presence: true
        validates :published_by, presence: true, on: :create
        validate :validate_published_by_is_release_author, on: :create

        scope :for_catalog_resources, ->(catalog_resources) { where(catalog_resource_id: catalog_resources) }
        scope :preloaded, -> { includes(:catalog_resource, project: [:route, { namespace: :route }], release: :author) }
        scope :by_name, ->(name) { joins(:release).merge(Release.where(tag: name)) }
        scope :by_sha, ->(sha) { joins(:release).merge(Release.where(sha: sha)) }
        scope :with_semver, -> { where.not(semver_major: nil) }
        scope :without_prerelease, -> { where(semver_prerelease: nil) }

        delegate :sha, :author_id, to: :release

        cache_markdown_field :readme

        before_create :sync_with_release
        after_destroy :update_catalog_resource
        after_save :update_catalog_resource

        class << self
          def latest(major = nil, minor = nil)
            raise ArgumentError, 'semver minor version used without major version' if minor.present? &&
              major.blank?

            relation = with_semver
            relation = relation.without_prerelease
            relation = relation.where(semver_major: major) if major
            relation = relation.where(semver_minor: minor) if minor

            relation.order_by_semantic_version_desc.first
          end

          def versions_for_catalog_resources(catalog_resources)
            return none if catalog_resources.empty?

            for_catalog_resources(catalog_resources).with_semver.order_by_semantic_version_desc
          end
        end

        def name
          semver.to_s
        end

        def commit
          project.commit_by(oid: sha)
        end

        def path
          Gitlab::Routing.url_helpers.project_tag_path(project, name)
        end

        def readme
          return unless project.repo_exists?

          project.repository.tree(sha).readme&.data
        end

        def sync_with_release!
          sync_with_release
          save!
        end

        private

        def sync_with_release
          self.released_at = release.released_at
        end

        def update_catalog_resource
          catalog_resource.update_latest_released_at!
        end

        # We require the published_by to be the same as the release author because
        # creating a release and publishing a version must be done in a single session via release-cli.
        def validate_published_by_is_release_author
          return if published_by == release.author

          errors.add(:published_by, 'must be the same as the release author')
        end
      end
    end
  end
end

Ci::Catalog::Resources::Version.prepend_mod_with('Ci::Catalog::Resources::Version')
