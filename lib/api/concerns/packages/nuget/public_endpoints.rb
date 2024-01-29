# frozen_string_literal: true

# NuGet Package Manager Client API

# These API endpoints are not consumed directly by users, so there is no documentation for the
# individual endpoints. They are called by the NuGet package manager client when users run commands
# like `nuget install` or `nuget push`. The usage of the GitLab NuGet registry is documented here:
# https://docs.gitlab.com/ee/user/packages/nuget_repository/

module API
  module Concerns
    module Packages
      module Nuget
        module PublicEndpoints
          extend ActiveSupport::Concern

          SHA256_REGEX = /SHA256:([a-f0-9]{64})/i

          included do
            # https://docs.microsoft.com/en-us/nuget/api/service-index
            desc 'The NuGet V3 Feed Service Index' do
              detail 'This feature was introduced in GitLab 12.6'
              success code: 200, model: ::API::Entities::Nuget::ServiceIndex
              failure [
                { code: 404, message: 'Not Found' }
              ]
              tags %w[nuget_packages]
            end
            get 'index', format: :json, urgency: :default do
              track_package_event(
                'cli_metadata',
                :nuget,
                **snowplow_gitlab_standard_context_without_auth.merge(category: 'API::NugetPackages')
              )

              present ::Packages::Nuget::ServiceIndexPresenter.new(project_or_group_without_auth),
                with: ::API::Entities::Nuget::ServiceIndex
            end

            desc 'The NuGet V2 Feed Service Index' do
              detail 'This feature was introduced in GitLab 16.2'
              success code: 200
              failure [
                { code: 404, message: 'Not Found' }
              ]
              tags %w[nuget_packages]
            end

            namespace :symbolfiles do
              after_validation do
                forbidden! unless symbol_server_enabled?
              end

              desc 'The NuGet Symbol File Download Endpoint' do
                detail 'This feature was introduced in GitLab 16.7'
                success code: 200
                failure [
                  { code: 400, message: 'Bad Request' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not Found' }
                ]
                headers Symbolchecksum: {
                  type: String,
                  desc: 'The SHA256 checksums of the symbol file',
                  required: true
                }
                tags %w[nuget_packages]
              end
              params do
                requires :file_name, allow_blank: false, type: String, desc: 'The symbol file name',
                  regexp: API::NO_SLASH_URL_PART_REGEX, documentation: { example: 'mynugetpkg.pdb' }
                requires :signature, allow_blank: false, type: String, desc: 'The symbol file signature',
                  regexp: API::NO_SLASH_URL_PART_REGEX,
                  documentation: { example: 'k813f89485474661234z7109cve5709eFFFFFFFF' }
                requires :same_file_name, same_as: :file_name
              end
              get '*file_name/*signature/*same_file_name', format: false, urgency: :low do
                bad_request!('Missing checksum header') if headers['Symbolchecksum'].blank?

                project_or_group_without_auth

                checksums = headers['Symbolchecksum'].scan(SHA256_REGEX).flatten

                symbol = ::Packages::Nuget::Symbol
                  .find_by_signature_and_file_and_checksum(
                    declared_params[:signature],
                    declared_params[:file_name],
                    checksums
                  )

                not_found!('Symbol') unless symbol

                present_carrierwave_file!(symbol.file)
              end
            end

            namespace '/v2' do
              get format: :xml, urgency: :low do
                env['api.format'] = :xml
                content_type 'application/xml; charset=utf-8'
                # needed to allow browser default inline styles in xml response
                header 'Content-Security-Policy', "nonce-#{SecureRandom.base64(16)}"

                track_package_event(
                  'cli_metadata',
                  :nuget,
                  **snowplow_gitlab_standard_context_without_auth.merge(category: 'API::NugetPackages', feed: 'v2')
                )

                present ::Packages::Nuget::V2::ServiceIndexPresenter
                          .new(project_or_group_without_auth)
                          .xml
              end

              # https://www.nuget.org/api/v2/$metadata
              desc 'The NuGet V2 Feed Package $metadata endpoint' do
                detail 'This feature was introduced in GitLab 16.3'
                success code: 200
                tags %w[nuget_packages]
              end

              get '$metadata', format: :xml, urgency: :low do
                env['api.format'] = :xml
                content_type 'application/xml; charset=utf-8'
                # needed to allow browser default inline styles in xml response
                header 'Content-Security-Policy', "nonce-#{SecureRandom.base64(16)}"

                present ::Packages::Nuget::V2::MetadataIndexPresenter.new.xml
              end
            end
          end
        end
      end
    end
  end
end
