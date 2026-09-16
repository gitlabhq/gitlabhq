# frozen_string_literal: true

module API
  module Admin
    class SshCertificates < ::API::Base
      include PaginationParams

      feature_category :source_code_management
      urgency :low

      before do
        authenticated_as_admin!
        not_found! unless InstanceSshCertificate.available?
      end

      namespace :admin do
        resource :ssh_certificates do
          desc 'List all instance SSH certificates' do
            hidden true
            detail 'Lists the trusted SSH certificate authority public keys for the instance.'
            success Entities::SshCertificate
            failure [
              { code: 401, message: 'Unauthorized' },
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not found' }
            ]
            is_array true
            tags %w[keys]
          end
          params do
            use :pagination
          end
          route_setting :lifecycle, :beta
          route_setting :authorization, permissions: :read_ssh_certificate, boundary_type: :instance,
            assignable_when: [:admin]
          get do
            present paginate(InstanceSshCertificate.order_id_desc), with: Entities::SshCertificate
          end

          desc 'Add an instance SSH certificate' do
            hidden true
            detail 'Adds a trusted SSH certificate authority public key for the instance.'
            success code: 201, model: Entities::SshCertificate
            failure [
              { code: 400, message: 'Bad request' },
              { code: 401, message: 'Unauthorized' },
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not found' },
              { code: 422, message: 'Unprocessable entity' }
            ]
            tags %w[keys]
          end
          params do
            requires :title, limit: 255, type: String, desc: 'The title of the SSH certificate'
            requires :key, limit: 5000, type: String, desc: 'The SSH certificate authority public key'
          end
          route_setting :lifecycle, :beta
          route_setting :authorization, permissions: :create_ssh_certificate, boundary_type: :instance,
            assignable_when: [:admin]
          post do
            result = ::InstanceSshCertificates::CreateService.new(
              current_user: current_user, params: declared_params(include_missing: false)
            ).execute

            if result.success?
              present result.payload, with: Entities::SshCertificate
            else
              render_api_error!(result.message, result.reason)
            end
          end

          desc 'Delete an instance SSH certificate' do
            hidden true
            detail 'Deletes a trusted SSH certificate authority public key from the instance.'
            success code: 204
            failure [
              { code: 400, message: 'Bad request' },
              { code: 401, message: 'Unauthorized' },
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not found' },
              { code: 422, message: 'Unprocessable entity' }
            ]
            tags %w[keys]
          end
          params do
            requires :id, type: Integer, desc: 'The ID of the instance SSH certificate'
          end
          route_setting :lifecycle, :beta
          route_setting :authorization, permissions: :delete_ssh_certificate, boundary_type: :instance,
            assignable_when: [:admin]
          delete ':id' do
            result = ::InstanceSshCertificates::DestroyService.new(params[:id], current_user: current_user).execute

            if result.success?
              no_content!
            else
              render_api_error!(result.message, result.reason)
            end
          end
        end
      end
    end
  end
end
