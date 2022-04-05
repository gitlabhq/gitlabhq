# frozen_string_literal: true

module API
  module Admin
    class Sidekiq < ::API::Base
      before { authenticated_as_admin! }

      feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned

      namespace 'admin' do
        namespace 'sidekiq' do
          namespace 'queues' do
            desc 'Drop jobs matching the given metadata from the Sidekiq queue'
            params do
              Gitlab::SidekiqQueue::ALLOWED_KEYS.each do |key|
                optional key, type: String, allow_blank: false
              end

              at_least_one_of(*Gitlab::SidekiqQueue::ALLOWED_KEYS)
            end
            delete ':queue_name' do
              result =
                Gitlab::SidekiqQueue
                  .new(params[:queue_name])
                  .drop_jobs!(declared_params, timeout: 30)

              present result
            rescue Gitlab::SidekiqQueue::NoMetadataError
              render_api_error!("Invalid metadata: #{declared_params}", 400)
            rescue Gitlab::SidekiqQueue::InvalidQueueError
              not_found!(params[:queue_name])
            end
          end
        end
      end
    end
  end
end
