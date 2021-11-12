# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module ProjectNamespaces
      module Models
        # isolated Namespace model
        class Namespace < ActiveRecord::Base
          include EachBatch

          self.table_name = 'namespaces'
          self.inheritance_column = :_type_disabled
        end
      end
    end
  end
end
