# frozen_string_literal: true

module Namespaces
  class TemplateSetting < ApplicationRecord
    self.table_name = 'namespace_template_settings'
    self.primary_key = :namespace_id

    belongs_to :namespace
    belongs_to :duo_template_project, class_name: 'Project', optional: true

    validates :namespace, presence: true
  end
end
