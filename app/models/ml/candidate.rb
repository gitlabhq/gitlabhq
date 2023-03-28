# frozen_string_literal: true

module Ml
  class Candidate < ApplicationRecord
    include Sortable
    include IgnorableColumns
    ignore_column :iid, remove_with: '16.0', remove_after: '2023-05-01'

    PACKAGE_PREFIX = 'ml_candidate_'

    enum status: { running: 0, scheduled: 1, finished: 2, failed: 3, killed: 4 }

    validates :iid, :experiment, presence: true
    validates :status, inclusion: { in: statuses.keys }

    belongs_to :experiment, class_name: 'Ml::Experiment'
    belongs_to :user
    belongs_to :package, class_name: 'Packages::Package'
    has_many :metrics, class_name: 'Ml::CandidateMetric'
    has_many :params, class_name: 'Ml::CandidateParam'
    has_many :metadata, class_name: 'Ml::CandidateMetadata'
    has_many :latest_metrics, -> { latest }, class_name: 'Ml::CandidateMetric', inverse_of: :candidate

    attribute :eid, default: -> { SecureRandom.uuid }

    scope :including_relationships, -> { includes(:latest_metrics, :params, :user, :package) }
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

    delegate :project_id, :project, to: :experiment

    alias_attribute :artifact, :package

    # Remove alias after https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115401
    alias_attribute :iid, :eid

    def artifact_root
      "/#{package_name}/#{package_version}/"
    end

    def package_name
      "#{PACKAGE_PREFIX}#{id}"
    end

    def package_version
      '-'
    end

    class << self
      def with_project_id_and_iid(project_id, iid)
        return unless project_id.present? && iid.present?

        joins(:experiment).find_by(experiment: { project_id: project_id }, eid: iid)
      end

      def candidate_id_for_package(package_name)
        return unless package_name.starts_with?(PACKAGE_PREFIX)

        id = package_name.delete_prefix(PACKAGE_PREFIX)

        return unless numeric?(id)

        id.to_i
      end

      def find_from_package_name(package_name)
        find_by_id(candidate_id_for_package(package_name))
      end

      private

      def numeric?(value)
        value.match?(/\A\d+\z/)
      end
    end
  end
end
