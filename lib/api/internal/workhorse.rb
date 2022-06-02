# frozen_string_literal: true

module API
  module Internal
    class Workhorse < ::API::Base
      feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned

      before do
        verify_workhorse_api!
        content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE
      end

      namespace 'internal' do
        namespace 'workhorse' do
          post 'authorize_upload' do
            authenticator = Gitlab::Auth::RequestAuthenticator.new(request)
            unauthorized! unless authenticator.find_authenticated_requester([:api])

            status 200
            { TempPath: File.join(::Gitlab.config.uploads.storage_path, 'uploads/tmp') }
          end
        end
      end
    end
  end
end
