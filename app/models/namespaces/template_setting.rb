# frozen_string_literal: true

module Namespaces
  class TemplateSetting < ApplicationRecord
    self.table_name = 'namespace_template_settings'
    self.primary_key = :namespace_id

    belongs_to :namespace
    belongs_to :file_template_project, class_name: 'Project', optional: true
    belongs_to :duo_template_project, class_name: 'Project', optional: true

    scope :with_namespace_ids, ->(namespace_ids) { where(namespace_id: namespace_ids) }
    scope :with_custom_project_templates, -> { where.not(custom_project_templates_group_id: nil) }

    validates :namespace, presence: true
    validate :custom_project_templates_group_allowed

    private

    def custom_project_templates_group_allowed
      return if custom_project_templates_group_id.blank?
      return if namespace&.children&.exists?(id: custom_project_templates_group_id)

      errors.add(:custom_project_templates_group_id, 'has to be a subgroup of the group')
    end
  end
end
