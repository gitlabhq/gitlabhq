# frozen_string_literal: true

module API
  module Concerns
    module Packages
      module DebianPackageEndpoints
        extend ActiveSupport::Concern

        DISTRIBUTION_REQUIREMENTS = {
          distribution: ::Packages::Debian::DISTRIBUTION_REGEX
        }.freeze
        COMPONENT_ARCHITECTURE_REQUIREMENTS = {
          component: ::Packages::Debian::COMPONENT_REGEX,
          architecture: ::Packages::Debian::ARCHITECTURE_REGEX
        }.freeze

        included do
          feature_category :package_registry

          helpers ::API::Helpers::PackagesHelpers
          helpers ::API::Helpers::Packages::BasicAuthHelpers
          include ::API::Helpers::Authentication

          helpers do
            params :shared_package_file_params do
              requires :distribution, type: String, desc: 'The Debian Codename or Suite', regexp: Gitlab::Regex.debian_distribution_regex
              requires :letter, type: String, desc: 'The Debian Classification (first-letter or lib-first-letter)'
              requires :package_name, type: String, desc: 'The Debian Source Package Name', regexp: Gitlab::Regex.debian_package_name_regex
              requires :package_version, type: String, desc: 'The Debian Source Package Version', regexp: Gitlab::Regex.debian_version_regex
              requires :file_name, type: String, desc: 'The Debian File Name'
            end

            def distribution_from!(container)
              ::Packages::Debian::DistributionsFinder.new(container, codename_or_suite: params[:distribution]).execute.last!
            end

            def present_package_file!
              not_found! unless params[:package_name].start_with?(params[:letter])

              package_file = distribution_from!(user_project).package_files.with_file_name(params[:file_name]).last!

              present_carrierwave_file!(package_file.file)
            end
          end

          authenticate_with do |accept|
            accept.token_types(:personal_access_token, :deploy_token, :job_token)
                  .sent_through(:http_basic_auth)
          end

          rescue_from ArgumentError do |e|
            render_api_error!(e.message, 400)
          end

          rescue_from ActiveRecord::RecordInvalid do |e|
            render_api_error!(e.message, 400)
          end

          format :txt
          content_type :txt, 'text/plain'

          params do
            requires :distribution, type: String, desc: 'The Debian Codename or Suite', regexp: Gitlab::Regex.debian_distribution_regex
          end

          namespace 'dists/*distribution', requirements: DISTRIBUTION_REQUIREMENTS do
            # GET {projects|groups}/:id/packages/debian/dists/*distribution/Release.gpg
            desc 'The Release file signature' do
              detail 'This feature was introduced in GitLab 13.5'
            end

            route_setting :authentication, authenticate_non_public: true
            get 'Release.gpg' do
              distribution_from!(project_or_group).file_signature
            end

            # GET {projects|groups}/:id/packages/debian/dists/*distribution/Release
            desc 'The unsigned Release file' do
              detail 'This feature was introduced in GitLab 13.5'
            end

            route_setting :authentication, authenticate_non_public: true
            get 'Release' do
              present_carrierwave_file!(distribution_from!(project_or_group).file)
            end

            # GET {projects|groups}/:id/packages/debian/dists/*distribution/InRelease
            desc 'The signed Release file' do
              detail 'This feature was introduced in GitLab 13.5'
            end

            route_setting :authentication, authenticate_non_public: true
            get 'InRelease' do
              present_carrierwave_file!(distribution_from!(project_or_group).signed_file)
            end

            params do
              requires :component, type: String, desc: 'The Debian Component', regexp: Gitlab::Regex.debian_component_regex
              requires :architecture, type: String, desc: 'The Debian Architecture', regexp: Gitlab::Regex.debian_architecture_regex
            end

            namespace ':component/binary-:architecture', requirements: COMPONENT_ARCHITECTURE_REQUIREMENTS do
              # GET {projects|groups}/:id/packages/debian/dists/*distribution/:component/binary-:architecture/Packages
              desc 'The binary files index' do
                detail 'This feature was introduced in GitLab 13.5'
              end

              route_setting :authentication, authenticate_non_public: true
              get 'Packages' do
                relation = "::Packages::Debian::#{project_or_group.class.name}ComponentFile".constantize

                component_file = relation
                  .preload_distribution
                  .with_container(project_or_group)
                  .with_codename_or_suite(params[:distribution])
                  .with_component_name(params[:component])
                  .with_file_type(:packages)
                  .with_architecture_name(params[:architecture])
                  .with_compression_type(nil)
                  .order_created_asc
                  .last!

                present_carrierwave_file!(component_file.file)
              end
            end
          end
        end
      end
    end
  end
end
