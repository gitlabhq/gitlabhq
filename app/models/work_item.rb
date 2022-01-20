# frozen_string_literal: true

class WorkItem < Issue
  self.table_name = 'issues'
  self.inheritance_column = :_type_disabled
end
