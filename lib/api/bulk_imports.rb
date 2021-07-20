# frozen_string_literal: true

module API
  class BulkImports < ::API::Base
    include PaginationParams

    feature_category :importers

    helpers do
      def bulk_imports
        @bulk_imports ||= ::BulkImports::ImportsFinder.new(user: current_user, status: params[:status]).execute
      end

      def bulk_import
        @bulk_import ||= bulk_imports.find(params[:import_id])
      end

      def bulk_import_entities
        @bulk_import_entities ||= ::BulkImports::EntitiesFinder.new(user: current_user, bulk_import: bulk_import, status: params[:status]).execute
      end

      def bulk_import_entity
        @bulk_import_entity ||= bulk_import_entities.find(params[:entity_id])
      end
    end

    before { authenticate! }

    resource :bulk_imports do
      desc 'List all GitLab Migrations' do
        detail 'This feature was introduced in GitLab 14.1.'
      end
      params do
        use :pagination
        optional :status, type: String, values: BulkImport.all_human_statuses,
                 desc: 'Return GitLab Migrations with specified status'
      end
      get do
        present paginate(bulk_imports), with: Entities::BulkImport
      end

      desc "List all GitLab Migrations' entities" do
        detail 'This feature was introduced in GitLab 14.1.'
      end
      params do
        use :pagination
        optional :status, type: String, values: ::BulkImports::Entity.all_human_statuses,
                 desc: "Return all GitLab Migrations' entities with specified status"
      end
      get :entities do
        entities = ::BulkImports::EntitiesFinder.new(user: current_user, status: params[:status]).execute

        present paginate(entities), with: Entities::BulkImports::Entity
      end

      desc 'Get GitLab Migration details' do
        detail 'This feature was introduced in GitLab 14.1.'
      end
      params do
        requires :import_id, type: Integer, desc: "The ID of user's GitLab Migration"
      end
      get ':import_id' do
        present bulk_import, with: Entities::BulkImport
      end

      desc "List GitLab Migration entities" do
        detail 'This feature was introduced in GitLab 14.1.'
      end
      params do
        requires :import_id, type: Integer, desc: "The ID of user's GitLab Migration"
        optional :status, type: String, values: ::BulkImports::Entity.all_human_statuses,
                 desc: 'Return import entities with specified status'
        use :pagination
      end
      get ':import_id/entities' do
        present paginate(bulk_import_entities), with: Entities::BulkImports::Entity
      end

      desc 'Get GitLab Migration entity details' do
        detail 'This feature was introduced in GitLab 14.1.'
      end
      params do
        requires :import_id, type: Integer, desc: "The ID of user's GitLab Migration"
        requires :entity_id, type: Integer, desc: "The ID of GitLab Migration entity"
      end
      get ':import_id/entities/:entity_id' do
        present bulk_import_entity, with: Entities::BulkImports::Entity
      end
    end
  end
end
