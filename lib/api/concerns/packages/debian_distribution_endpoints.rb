# frozen_string_literal: true

module API
  module Concerns
    module Packages
      module DebianDistributionEndpoints
        extend ActiveSupport::Concern

        included do
          include PaginationParams

          feature_category :package_registry
          urgency :low

          helpers ::API::Helpers::PackagesHelpers
          helpers ::API::Helpers::Packages::BasicAuthHelpers
          include ::API::Helpers::Authentication

          helpers do
            def distribution
              ::Packages::Debian::DistributionsFinder.new(project_or_group, codename: params[:codename]).execute.last || not_found!('Distribution')
            end
          end

          namespace 'debian_distributions' do
            helpers do
              params :optional_distribution_params do
                optional :suite, type: String, regexp: Gitlab::Regex.debian_distribution_regex, desc: 'The Debian Suite', documentation: { example: 'unstable' }
                optional :origin, type: String, regexp: Gitlab::Regex.debian_distribution_regex, desc: 'The Debian Origin', documentation: { example: 'Grep' }
                optional :label, type: String, regexp: Gitlab::Regex.debian_distribution_regex, desc: 'The Debian Label', documentation: { example: 'grep.be' }
                optional :version, type: String, regexp: Gitlab::Regex.debian_version_regex, desc: 'The Debian Version', documentation: { example: '12' }
                optional :description, type: String, desc: 'The Debian Description', documentation: { example: 'My description' }
                optional :valid_time_duration_seconds, type: Integer, desc: 'The duration before the Release file should be considered expired by the client', documentation: { example: 604800 }

                optional :components, type: Array[String],
                  coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce,
                  regexp: Gitlab::Regex.debian_component_regex,
                  desc: 'The list of Components',
                  documentation: { example: 'main' }
                optional :architectures, type: Array[String],
                  coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce,
                  regexp: Gitlab::Regex.debian_architecture_regex,
                  desc: 'The list of Architectures',
                  documentation: { example: 'amd64' }
              end
            end

            rescue_from ArgumentError do |e|
              render_api_error!(e.message, 400)
            end

            rescue_from ActiveRecord::RecordInvalid do |e|
              render_api_error!(e.message, 400)
            end

            authenticate_with do |accept|
              accept.token_types(:personal_access_token).sent_through(:http_private_token_header)
              accept.token_types(:deploy_token).sent_through(:http_deploy_token_header)
              accept.token_types(:job_token).sent_through(:http_job_token_header)
            end

            content_type :json, 'application/json'
            format :json

            # POST {projects|groups}/:id/debian_distributions
            desc 'Create a Debian Distribution' do
              detail 'This feature was introduced in 14.0'
              success code: 201, model: ::API::Entities::Packages::Debian::Distribution
              failure [
                { code: 400, message: 'Bad Request' },
                { code: 401, message: 'Unauthorized' },
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not Found' }
              ]
              tags %w[debian_distribution]
            end

            params do
              requires :codename, type: String, regexp: Gitlab::Regex.debian_distribution_regex, desc: 'The Debian Codename', documentation: { example: 'sid' }
              use :optional_distribution_params
            end
            post '/' do
              authorize_create_package!(project_or_group(:read_project))

              distribution_params = declared_params(include_missing: false)
              result = ::Packages::Debian::CreateDistributionService.new(project_or_group(:read_project), current_user, distribution_params).execute
              created_distribution = result.payload[:distribution]

              if result.success?
                present created_distribution, with: ::API::Entities::Packages::Debian::Distribution
              else
                render_validation_error!(created_distribution)
              end
            end

            # GET {projects|groups}/:id/debian_distributions
            desc 'Get a list of Debian Distributions' do
              detail 'This feature was introduced in 14.0'
              success code: 200, model: ::API::Entities::Packages::Debian::Distribution
              failure [
                { code: 401, message: 'Unauthorized' },
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not Found' }
              ]
              tags %w[debian_distribution]
            end

            params do
              use :pagination
              optional :codename, type: String, regexp: Gitlab::Regex.debian_distribution_regex, desc: 'The Debian Codename', documentation: { example: 'sid' }
              use :optional_distribution_params
            end
            get '/' do
              authorize_read_package!(project_or_group)

              distribution_params = declared_params(include_missing: false)
              distributions = ::Packages::Debian::DistributionsFinder.new(project_or_group, distribution_params).execute

              present paginate(distributions), with: ::API::Entities::Packages::Debian::Distribution
            end

            # GET {projects|groups}/:id/debian_distributions/:codename
            desc 'Get a Debian Distribution' do
              detail 'This feature was introduced in 14.0'
              success code: 200, model: ::API::Entities::Packages::Debian::Distribution
              failure [
                { code: 401, message: 'Unauthorized' },
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not Found' }
              ]
              tags %w[debian_distribution]
            end

            params do
              requires :codename, type: String, regexp: Gitlab::Regex.debian_distribution_regex, desc: 'The Debian Codename', documentation: { example: 'sid' }
            end
            get '/:codename' do
              authorize_read_package!(project_or_group)

              present distribution, with: ::API::Entities::Packages::Debian::Distribution
            end

            # GET {projects|groups}/:id/debian_distributions/:codename/key
            desc 'Get a Debian Distribution Key' do
              detail 'This feature was introduced in 14.4'
              success code: 200, model: ::API::Entities::Packages::Debian::Distribution
              failure [
                { code: 401, message: 'Unauthorized' },
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not Found' }
              ]
              tags %w[debian_distribution]
            end

            params do
              requires :codename, type: String, regexp: Gitlab::Regex.debian_distribution_regex, desc: 'The Debian Codename', documentation: { example: 'sid' }
            end
            get '/:codename/key.asc' do
              authorize_read_package!(project_or_group)

              content_type 'text/plain'
              env['api.format'] = :binary
              header 'Content-Disposition', "attachment; filename*=UTF-8''#{CGI.escape(params[:codename])}.asc"

              distribution.key&.public_key || not_found!('Distribution key')
            end

            # PUT {projects|groups}/:id/debian_distributions/:codename
            desc 'Update a Debian Distribution' do
              detail 'This feature was introduced in 14.0'
              success code: 200, model: ::API::Entities::Packages::Debian::Distribution
              failure [
                { code: 400, message: 'Bad Request' },
                { code: 401, message: 'Unauthorized' },
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not Found' }
              ]
              tags %w[debian_distribution]
            end

            params do
              requires :codename, type: String, regexp: Gitlab::Regex.debian_distribution_regex, desc: 'The Debian Codename', documentation: { example: 'sid' }
              use :optional_distribution_params
            end
            put '/:codename' do
              authorize_create_package!(project_or_group(:read_project))

              distribution_params = declared_params(include_missing: false).except(:codename)
              result = ::Packages::Debian::UpdateDistributionService.new(distribution, distribution_params).execute
              updated_distribution = result.payload[:distribution]

              if result.success?
                present updated_distribution, with: ::API::Entities::Packages::Debian::Distribution
              else
                render_validation_error!(updated_distribution)
              end
            end

            # DELETE {projects|groups}/:id/debian_distributions/:codename
            desc 'Delete a Debian Distribution' do
              detail 'This feature was introduced in 14.0'
              success code: 202
              failure [
                { code: 400, message: 'Bad Request' },
                { code: 401, message: 'Unauthorized' },
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not Found' }
              ]
              tags %w[debian_distribution]
            end

            params do
              requires :codename, type: String, regexp: Gitlab::Regex.debian_distribution_regex, desc: 'The Debian Codename', documentation: { example: 'sid' }
              use :optional_distribution_params
            end
            delete '/:codename' do
              authorize_destroy_package!(project_or_group(:read_project))

              accepted! if distribution.destroy

              render_api_error!('Failed to delete distribution', 400)
            end
          end
        end
      end
    end
  end
end
