# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Remove duplicated service records with the same project and type.
    # These were created in the past for unknown reasons, and should be blocked
    # now by the uniqueness validation in the Service model.
    class RemoveDuplicateServices
      # See app/models/service
      class Service < ActiveRecord::Base
        include EachBatch

        self.table_name = 'services'
        self.inheritance_column = :_type_disabled

        scope :project_ids_with_duplicates, -> do
          select(:project_id)
            .distinct
            .where.not(project_id: nil)
            .group(:project_id, :type)
            .having('count(*) > 1')
        end

        scope :types_with_duplicates, -> (project_ids) do
          select(:project_id, :type)
            .where(project_id: project_ids)
            .group(:project_id, :type)
            .having('count(*) > 1')
        end
      end

      def perform(*project_ids)
        types_with_duplicates = Service.types_with_duplicates(project_ids).pluck(:project_id, :type)

        types_with_duplicates.each do |project_id, type|
          remove_duplicates(project_id, type)
        end
      end

      private

      def remove_duplicates(project_id, type)
        scope = Service.where(project_id: project_id, type: type)

        # Build a subquery to determine which service record is actually in use,
        # by querying for it without specifying an order.
        #
        # This should match the record returned by `Project#find_service`,
        # and the `has_one` service associations on `Project`.
        correct_service = scope.select(:id).limit(1)

        # Delete all other services with the same `project_id` and `type`
        duplicate_services = scope.where.not(id: correct_service)
        duplicate_services.delete_all
      end
    end
  end
end
