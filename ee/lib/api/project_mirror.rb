require_dependency 'declarative_policy'

module API
  class ProjectMirror < Grape::API
    helpers do
      def github_webhook_signature
        @github_webhook_signature ||= headers['X-Hub-Signature']
      end

      def authenticate_from_github_webhook!
        return unless github_webhook_signature

        unless valid_github_signature?
          Guest.can?(:read_project, project) ? unauthorized! : not_found!
        end
      end

      def valid_github_signature?
        request.body.rewind

        token        = project.external_webhook_token
        payload_body = request.body.read
        signature    = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), token, payload_body)

        Rack::Utils.secure_compare(signature, github_webhook_signature)
      end

      def authenticate_with_webhook_token!
        if github_webhook_signature
          not_found! unless project

          authenticate_from_github_webhook!
        else
          authenticate!
          authorize_admin_project
        end
      end

      def project
        @project ||= github_webhook_signature ? find_project(params[:id]) : user_project
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      desc 'Triggers a pull mirror operation'
      post ":id/mirror/pull" do
        authenticate_with_webhook_token!

        return render_api_error!('The project is not mirrored', 400) unless project.mirror?

        project.force_import_job!

        status 200
      end
    end
  end
end
