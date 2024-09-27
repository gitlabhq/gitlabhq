# frozen_string_literal: true

class Group::CrmSettings < ApplicationRecord
  self.primary_key = :group_id
  self.table_name = 'group_crm_settings'

  belongs_to :group, -> { where(type: Group.sti_name) }, foreign_key: 'group_id'
  belongs_to :source_group, -> { where(type: Group.sti_name) }, foreign_key: 'source_group_id', class_name: 'Group'

  validates :group, presence: true
end
