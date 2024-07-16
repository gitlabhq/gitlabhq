# frozen_string_literal: true

module AuditEvents
  class GroupAuditEvent < ApplicationRecord
    self.table_name = "group_audit_events"

    include AuditEvents::CommonModel
    include ::Gitlab::Utils::StrongMemoize

    validates :group_id, presence: true

    scope :by_group, ->(group_id) { where(group_id: group_id) }

    attr_accessor :root_group_entity_id
    attr_writer :group

    def group
      lazy_group
    end
    strong_memoize_attr :group

    def root_group_entity
      return ::Group.find_by(id: root_group_entity_id) if root_group_entity_id.present?
      return if group.nil?

      root_group_entity = group.root_ancestor
      self.root_group_entity_id = root_group_entity.id
      root_group_entity
    end
    strong_memoize_attr :root_group_entity

    private

    def lazy_group
      BatchLoader.for(group_id)
                 .batch(default_value: ::Gitlab::Audit::NullEntity.new
                       ) do |ids, loader|
        ::Group.where(id: ids).find_each { |record| loader.call(record.id, record) }
      end
    end
  end
end
