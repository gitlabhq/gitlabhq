# frozen_string_literal: true

module API
  module Internal
    class Workhorse < ::API::Base
      feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned

      before do
        verify_workhorse_api!
        content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE
      end

      helpers do
        def request_authenticated?
          authenticator = Gitlab::Auth::RequestAuthenticator.new(request)
          return true if authenticator.find_authenticated_requester([:api])

          # Look up user from warden, ignoring the absence of a CSRF token. For
          # web users the CSRF token can be in the POST form data but Workhorse
          # does not propagate the form data to us.
          !!request.env['warden']&.authenticate
        end
      end

      namespace 'internal' do
        namespace 'workhorse' do
          post 'authorize_upload' do
            unauthorized! unless request_authenticated?

            status 200
            { TempPath: File.join(::Gitlab.config.uploads.storage_path, 'uploads/tmp') }
          end
        end
      end
    end
  end
end
