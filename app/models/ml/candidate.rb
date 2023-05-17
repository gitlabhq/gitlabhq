# frozen_string_literal: true

module Ml
  class Candidate < ApplicationRecord
    include Sortable
    include AtomicInternalId
    include IgnorableColumns

    ignore_column :iid, remove_with: '16.0', remove_after: '2023-05-01'

    enum status: { running: 0, scheduled: 1, finished: 2, failed: 3, killed: 4 }

    validates :eid, :experiment, presence: true
    validates :status, inclusion: { in: statuses.keys }

    belongs_to :experiment, class_name: 'Ml::Experiment'
    belongs_to :user
    belongs_to :package, class_name: 'Packages::Package'
    belongs_to :project
    belongs_to :ci_build, class_name: 'Ci::Build', optional: true
    has_many :metrics, class_name: 'Ml::CandidateMetric'
    has_many :params, class_name: 'Ml::CandidateParam'
    has_many :metadata, class_name: 'Ml::CandidateMetadata'
    has_many :latest_metrics, -> { latest }, class_name: 'Ml::CandidateMetric', inverse_of: :candidate

    attribute :eid, default: -> { SecureRandom.uuid }

    has_internal_id :internal_id,
      scope: :project,
      init: AtomicInternalId.project_init(self, :internal_id)

    scope :including_relationships, -> { includes(:latest_metrics, :params, :user, :package, :project, :ci_build) }
    scope :by_name, ->(name) { where("ml_candidates.name LIKE ?", "%#{sanitize_sql_like(name)}%") } # rubocop:disable GitlabSecurity/SqlInjection

    scope :order_by_metric, ->(metric, direction) do
      subquery = Ml::CandidateMetric.latest.where(name: metric)
      column_expression = Arel::Table.new('latest')[:value]
      metric_order_expression = direction.to_sym == :desc ? column_expression.desc : column_expression.asc

      joins("INNER JOIN (#{subquery.to_sql}) latest ON latest.candidate_id = ml_candidates.id")
        .select("ml_candidates.*", "latest.value as metric_value")
        .order(
          Gitlab::Pagination::Keyset::Order.build(
            [
              Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
                attribute_name: 'metric_value',
                order_expression: metric_order_expression,
                nullable: :nulls_last,
                distinct: false
              ),
              Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
                attribute_name: 'id',
                order_expression: arel_table[:id].desc
              )
            ])
        )
    end

    alias_attribute :artifact, :package
    alias_attribute :iid, :internal_id

    delegate :package_name, to: :experiment

    def artifact_root
      "/#{package_name}/#{package_version}/"
    end

    def package_version
      iid
    end

    def from_ci?
      ci_build_id.present?
    end

    class << self
      def with_project_id_and_eid(project_id, eid)
        return unless project_id.present? && eid.present?

        find_by(project_id: project_id, eid: eid)
      end

      def with_project_id_and_iid(project_id, iid)
        return unless project_id.present? && iid.present?

        find_by(project_id: project_id, internal_id: iid)
      end
    end
  end
end
