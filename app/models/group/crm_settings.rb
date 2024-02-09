# frozen_string_literal: true

class Group::CrmSettings < ApplicationRecord
  include SafelyChangeColumnDefault

  self.primary_key = :group_id
  self.table_name = 'group_crm_settings'

  belongs_to :group, -> { where(type: Group.sti_name) }, foreign_key: 'group_id'

  validates :group, presence: true

  columns_changing_default :enabled
end
