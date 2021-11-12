# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module ProjectNamespaces
      module Models
        # isolated Project model
        class Project < ActiveRecord::Base
          include EachBatch

          self.table_name = 'projects'
        end
      end
    end
  end
end
