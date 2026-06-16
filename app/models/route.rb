# frozen_string_literal: true

class Route < ApplicationRecord
  include CaseSensitivity
  include Gitlab::SQL::Pattern
  include EachBatch
  include AfterCommitQueue
  include Cells::Claimable

  cells_claims_scope do
    where("strpos(path, '/') = 0")
  end

  cells_claims_attribute :path, type: CLAIMS_BUCKET_TYPE::ROUTES,
    feature_flag: :cells_claims_routes,
    if: ->(record) { record.path.exclude?('/') }

  cells_claims_metadata subject_type: CLAIMS_SUBJECT_TYPE::NAMESPACE, subject_key: :namespace_id

  belongs_to :source, polymorphic: true, inverse_of: :route # rubocop:disable Cop/PolymorphicAssociations
  belongs_to :namespace, inverse_of: :namespace_route
  validates :source, presence: true

  validates :path,
    length: { within: 1..255 },
    presence: true,
    uniqueness: { case_sensitive: false }

  after_create :delete_conflicting_redirects
  after_update :delete_conflicting_redirects, if: :saved_change_to_path?
  after_update :create_redirect_for_old_path
  after_update :rename_descendants
  # Anchored on Route (rather than a service) to catch every path-vacating flow
  # in one place. Callback bypasses (e.g. upsert_all in RenameDescendantsService)
  # are handled explicitly via Authn::BurnedProjectRoute.bulk_burn!.
  after_update :burn_vacated_project_path, if: -> { saved_change_to_path? && project_route? }
  before_destroy :burn_project_path, if: :project_route?

  scope :by_paths, ->(paths) { where(arel_table[:path].lower.in(paths.map(&:downcase))) }
  scope :inside_path, ->(path) { where('routes.path LIKE ?', "#{sanitize_sql_like(path)}/%") }
  scope :for_routable, ->(routable) { where(source: routable) }
  scope :for_routable_type, ->(routable_type) { where(source_type: routable_type) }
  scope :sort_by_path_length, -> { order('LENGTH(routes.path)', :path) }

  def rename_descendants
    return unless saved_change_to_path? || saved_change_to_name?

    changes = {
      path: { saved: saved_change_to_path?, old_value: path_before_last_save },
      name: { saved: saved_change_to_name?, old_value: name_before_last_save }
    }

    Routes::RenameDescendantsService.new(self).execute(changes) # rubocop: disable CodeReuse/ServiceClass -- Need a service class to encapsulate all the logic.
  end

  def delete_conflicting_redirects
    destroy_metadata = []

    if RedirectRoute.cells_claims_enabled_for_attribute?(:path)
      conflicting_redirects.each_batch(of: Cells::Claimable::BULK_CLAIMS_BATCH_SIZE) do |batch|
        destroy_metadata.concat(
          batch.filter_map { |record| record.build_destroy_metadata_for_worker(:path) }
        )
      end
    end

    conflicting_redirects.delete_all

    return if destroy_metadata.empty?

    run_after_commit do
      destroy_metadata.each_slice(Cells::Claimable::BULK_CLAIMS_BATCH_SIZE) do |slice|
        Cells::BulkClaimsWorker.perform_async(RedirectRoute.name, 'path', { 'destroy_metadata' => slice })
      end
    end
  end

  def conflicting_redirects
    RedirectRoute.matching_path_and_descendants(path)
  end

  def create_redirect(path)
    RedirectRoute.create(source: source, path: path)
  end

  private

  def create_redirect_for_old_path
    create_redirect(path_before_last_save) if saved_change_to_path?
  end

  def burn_vacated_project_path
    old_path = path_before_last_save
    return if old_path.blank?

    ::Authn::BurnedProjectRoute.burn!(
      organization_id: burn_organization_id,
      path: old_path,
      project_id: burn_project_id
    )
  end

  def burn_project_path
    ::Authn::BurnedProjectRoute.burn!(
      organization_id: burn_organization_id,
      path: path,
      project_id: burn_project_id
    )
  end

  # Project destroy services may nullify the polymorphic association in
  # memory before the route's own before_destroy fires; fall back to the
  # persisted column so the burn record is never orphaned.
  def burn_project_id
    source_id_in_database || source_id
  end

  # Resolve organization_id from the persisted project row. We re-read it from
  # the database (rather than going through the in-memory association) because
  # destroy services may have already detached `source` by the time the route's
  # own before_destroy callback fires.
  #
  # When the project is being transferred across organizations and renamed at
  # the same time, the in-memory source carries the previous organization_id
  # via dirty tracking. Prefer that value so the burn lands under the *source*
  # organization (where the path was vacated), not the destination one.
  def burn_organization_id
    pid = burn_project_id
    return if pid.blank?

    if source.is_a?(Project)
      prior_org_id = source.organization_id_before_last_save
      return prior_org_id if prior_org_id.present?
    end

    Project.unscoped.where(id: pid).pick(:organization_id)
  end

  def project_route?
    (source_type_in_database || source_type) == 'Project'
  end

  def unique_attributes
    [:path]
  end
end
