# frozen_string_literal: true

module Ml
  class ModelVersion < ApplicationRecord
    include Presentable
    include Sortable
    include SemanticVersionable
    include CacheMarkdownField

    validates :project, :model, presence: true

    validates :version,
      format: Gitlab::Regex.semver_regex,
      uniqueness: { scope: [:project, :model_id] },
      presence: true,
      length: { maximum: 255 }

    validates :description,
      length: { maximum: 10_000 }

    validate :valid_model?, :valid_package?

    belongs_to :model, class_name: 'Ml::Model'
    belongs_to :project
    belongs_to :package, class_name: 'Packages::MlModel::Package', optional: true
    has_one :candidate, class_name: 'Ml::Candidate'
    has_many :metadata, class_name: 'Ml::ModelVersionMetadata'

    delegate :name, to: :model

    scope :order_by_model_id_id_desc, -> { order('model_id, id DESC') }
    scope :latest_by_model, -> {
                              order(model_id: :desc, semver_major: :desc, semver_minor: :desc, semver_patch: :desc)
                                .select('DISTINCT ON (model_id) *')
                            }
    scope :by_version, ->(version) { where("version LIKE ?", "#{sanitize_sql_like(version)}%") }
    scope :for_model, ->(model) { where(project: model.project, model: model) }
    scope :including_relations, -> { includes(:project, :model, :candidate) }
    scope :order_by_version, ->(order) { reorder(version: order) }

    cache_markdown_field :description

    def add_metadata(metadata_key_value)
      return unless metadata_key_value.present?

      metadata_key_value.each do |entry|
        metadata.create!(
          project_id: project_id,
          name: entry[:key],
          value: entry[:value]
        )
      end
    end

    class << self
      def find_or_create!(model, version, package, description)
        create_with(package: package, description: description)
          .find_or_create_by!(project: model.project, model: model, version: version)
      end

      def by_project_id_and_id(project_id, id)
        find_by(project_id: project_id, id: id)
      end

      def by_project_id_name_and_version(project_id, name, version)
        joins(:model).find_by(model: { name: name, project_id: project_id }, project_id: project_id, version: version)
      end
    end

    def version=(value)
      self.semver = value
      super(value)
    end

    private

    def valid_model?
      return unless model

      errors.add(:model, 'model project must be the same') unless model.project_id == project_id
    end

    def valid_package?
      return unless package

      errors.add(:package, 'package must be ml_model') unless package.ml_model?
      errors.add(:package, 'package name must be the same') unless package.name == name
      errors.add(:package, 'package version must be the same') unless package.version == version
      errors.add(:package, 'package project must be the same') unless package.project_id == project_id
    end
  end
end
