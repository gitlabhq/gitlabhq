# frozen_string_literal: true

module API
  module Concerns
    module Packages
      module DebianDistributionEndpoints
        extend ActiveSupport::Concern

        included do
          include PaginationParams

          feature_category :package_registry

          helpers ::API::Helpers::PackagesHelpers
          helpers ::API::Helpers::Packages::BasicAuthHelpers
          include ::API::Helpers::Authentication

          namespace 'debian_distributions' do
            helpers do
              params :optional_distribution_params do
                optional :suite, type: String, regexp: Gitlab::Regex.debian_distribution_regex, desc: 'The Debian Suite'
                optional :origin, type: String, regexp: Gitlab::Regex.debian_distribution_regex, desc: 'The Debian Origin'
                optional :label, type: String, regexp: Gitlab::Regex.debian_distribution_regex, desc: 'The Debian Label'
                optional :version, type: String, regexp: Gitlab::Regex.debian_version_regex, desc: 'The Debian Version'
                optional :description, type: String, desc: 'The Debian Description'
                optional :valid_time_duration_seconds, type: Integer, desc: 'The duration before the Release file should be considered expired by the client'

                optional :components, type: Array[String],
                  coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce,
                  regexp: Gitlab::Regex.debian_component_regex,
                  desc: 'The list of Components'
                optional :architectures, type: Array[String],
                  coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce,
                  regexp: Gitlab::Regex.debian_architecture_regex,
                  desc: 'The list of Architectures'
              end
            end

            authenticate_with do |accept|
              accept.token_types(:personal_access_token, :deploy_token, :job_token)
                    .sent_through(:http_basic_auth)
            end

            content_type :json, 'application/json'
            format :json

            # POST {projects|groups}/:id/debian_distributions
            desc 'Create a Debian Distribution' do
              detail 'This feature was introduced in 14.0'
              success ::API::Entities::Packages::Debian::Distribution
            end

            params do
              requires :codename, type: String, regexp: Gitlab::Regex.debian_distribution_regex, desc: 'The Debian Codename'
              use :optional_distribution_params
            end
            post '/' do
              authorize_create_package!(project_or_group)

              distribution_params = declared_params(include_missing: false)
              result = ::Packages::Debian::CreateDistributionService.new(project_or_group, current_user, distribution_params).execute
              distribution = result.payload[:distribution]

              if result.success?
                present distribution, with: ::API::Entities::Packages::Debian::Distribution
              else
                render_validation_error!(distribution)
              end
            end

            # GET {projects|groups}/:id/debian_distributions
            desc 'Get a list of Debian Distributions' do
              detail 'This feature was introduced in 14.0'
              success ::API::Entities::Packages::Debian::Distribution
            end

            params do
              use :pagination
              optional :codename, type: String, regexp: Gitlab::Regex.debian_distribution_regex, desc: 'The Debian Codename'
              use :optional_distribution_params
            end
            get '/' do
              distribution_params = declared_params(include_missing: false)
              distributions = ::Packages::Debian::DistributionsFinder.new(project_or_group, distribution_params).execute

              present paginate(distributions), with: ::API::Entities::Packages::Debian::Distribution
            end

            # GET {projects|groups}/:id/debian_distributions/:codename
            desc 'Get a Debian Distribution' do
              detail 'This feature was introduced in 14.0'
              success ::API::Entities::Packages::Debian::Distribution
            end

            params do
              requires :codename, type: String, regexp: Gitlab::Regex.debian_distribution_regex, desc: 'The Debian Codename'
            end
            get '/:codename' do
              distribution = ::Packages::Debian::DistributionsFinder.new(project_or_group, codename: params[:codename]).execute.last!

              present distribution, with: ::API::Entities::Packages::Debian::Distribution
            end

            # PUT {projects|groups}/:id/debian_distributions/:codename
            desc 'Update a Debian Distribution' do
              detail 'This feature was introduced in 14.0'
              success ::API::Entities::Packages::Debian::Distribution
            end

            params do
              requires :codename, type: String, regexp: Gitlab::Regex.debian_distribution_regex, desc: 'The Debian Codename'
              use :optional_distribution_params
            end
            put '/:codename' do
              authorize_create_package!(project_or_group)

              distribution = ::Packages::Debian::DistributionsFinder.new(project_or_group, codename: params[:codename]).execute.last!
              distribution_params = declared_params(include_missing: false).except(:codename)
              result = ::Packages::Debian::UpdateDistributionService.new(distribution, distribution_params).execute
              distribution = result.payload[:distribution]

              if result.success?
                present distribution, with: ::API::Entities::Packages::Debian::Distribution
              else
                render_validation_error!(distribution)
              end
            end

            # DELETE {projects|groups}/:id/debian_distributions/:codename
            desc 'Delete a Debian Distribution' do
              detail 'This feature was introduced in 14.0'
            end

            params do
              requires :codename, type: String, regexp: Gitlab::Regex.debian_distribution_regex, desc: 'The Debian Codename'
              use :optional_distribution_params
            end
            delete '/:codename' do
              authorize_destroy_package!(project_or_group)

              distribution = ::Packages::Debian::DistributionsFinder.new(project_or_group, codename: params[:codename]).execute.last!

              accepted! if distribution.destroy

              render_api_error!('Failed to delete distribution', 400)
            end
          end
        end
      end
    end
  end
end
