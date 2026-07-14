# frozen_string_literal: true

module Authn
  class BurnedProjectRoute < ::ApplicationRecord
    self.table_name = 'burned_project_routes'

    belongs_to :organization, class_name: 'Organizations::Organization'

    validates :organization_id, presence: true
    validates :path, presence: true
    validates :project_id, presence: true
    validates :burned_at, presence: true

    scope :for_path, ->(path) { where('LOWER(path) = LOWER(?)', path) }

    def self.blocked_for?(organization_id:, path:, except_project_id:)
      return false if organization_id.blank?

      relation = where(organization_id: organization_id).merge(for_path(path))
      return relation.exists? if except_project_id.blank?

      relation.where.not(project_id: except_project_id).exists?
    end

    def self.burn!(organization_id:, path:, project_id:)
      now = Time.current
      insert_all(
        [{
          organization_id: organization_id,
          path: path,
          project_id: project_id,
          burned_at: now,
          created_at: now,
          updated_at: now
        }],
        unique_by: 'index_burned_project_routes_on_org_id_lower_path'
      )
    end

    def self.bulk_burn!(rows)
      return if rows.blank?

      now = Time.current
      project_ids = rows.filter_map { |r| r[:project_id] }.uniq
      org_id_by_project_id = ::Project
        .unscoped
        .where(id: project_ids)
        .limit(project_ids.size)
        .pluck(:id, :organization_id)
        .to_h

      payloads = rows.filter_map do |r|
        org_id = org_id_by_project_id[r[:project_id]]
        next unless org_id && r[:path].present?

        {
          organization_id: org_id,
          path: r[:path],
          project_id: r[:project_id],
          burned_at: now,
          created_at: now,
          updated_at: now
        }
      end

      return if payloads.empty?

      insert_all(
        payloads,
        unique_by: 'index_burned_project_routes_on_org_id_lower_path'
      )
    end
  end
end
