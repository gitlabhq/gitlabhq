# frozen_string_literal: true

module AuditEvents
  class ProjectAuditEvent < ApplicationRecord
    self.table_name = "project_audit_events"

    include AuditEvents::CommonModel
    include ::Gitlab::Utils::StrongMemoize

    validates :project_id, presence: true

    scope :by_project, ->(project_id) { where(project_id: project_id) }

    attr_accessor :root_group_entity_id
    attr_writer :project

    def project
      lazy_project
    end
    strong_memoize_attr :project

    def root_group_entity
      return ::Group.find_by(id: root_group_entity_id) if root_group_entity_id.present?
      return if project.nil?

      root_group_entity = project.group&.root_ancestor
      self.root_group_entity_id = root_group_entity&.id
      root_group_entity
    end
    strong_memoize_attr :root_group_entity

    private

    def lazy_project
      BatchLoader.for(project_id)
                 .batch(default_value: ::Gitlab::Audit::NullEntity.new
                       ) do |ids, loader|
        ::Project.where(id: ids).find_each { |record| loader.call(record.id, record) }
      end
    end
  end
end
