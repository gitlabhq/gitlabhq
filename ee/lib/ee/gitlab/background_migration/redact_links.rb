# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module RedactLinks
        class Epic < ActiveRecord::Base
          include EachBatch
          include ::Gitlab::BackgroundMigration::RedactLinks::Redactable

          self.table_name = 'epics'
          self.inheritance_column = :_type_disabled
        end
      end
    end
  end
end
