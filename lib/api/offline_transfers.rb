# frozen_string_literal: true

module API
  class OfflineTransfers < ::API::Base
    include PaginationParams

    feature_category :importers
    urgency :low # Allow more time to validate migration config for immediate user feedback in API responses

    helpers do
      def offline_exports
        @offline_exports ||= ::Import::Offline::ExportsFinder.new(
          user: current_user,
          params: params.slice(:sort, :status)
        ).execute
      end

      def offline_export
        @offline_export ||= offline_exports.find(params[:id])
      end
    end

    before do
      not_found! unless Feature.enabled?(:offline_transfer_exports, current_user)

      authenticate!
    end

    resource :offline_exports do
      desc 'List all offline transfer exports'
      params do
        use :pagination
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
          desc: 'Return offline transfer exports sorted in created by `asc` or `desc` order.'
        optional :status, type: String, values: Import::Offline::Export.all_human_statuses,
          desc: 'Return offline transfer exports with specified status'
      end
      get do
        present paginate(offline_exports), with: Entities::Import::Offline::Export
      end

      desc 'Get offline transfer export details'
      params do
        requires :id, type: Integer, desc: "The ID of user's offline transfer export"
      end
      get ':id' do
        present offline_export, with: Entities::Import::Offline::Export
      end
    end
  end
end
