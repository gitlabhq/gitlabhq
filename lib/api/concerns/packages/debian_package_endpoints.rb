# frozen_string_literal: true

module API
  module Concerns
    module Packages
      module DebianPackageEndpoints
        extend ActiveSupport::Concern

        LETTER_REGEX = %r{(lib)?[a-z0-9]}.freeze
        PACKAGE_REGEX = API::NO_SLASH_URL_PART_REGEX
        DISTRIBUTION_REQUIREMENTS = {
          distribution: ::Packages::Debian::DISTRIBUTION_REGEX
        }.freeze
        COMPONENT_ARCHITECTURE_REQUIREMENTS = {
          component: ::Packages::Debian::COMPONENT_REGEX,
          architecture: ::Packages::Debian::ARCHITECTURE_REGEX
        }.freeze
        COMPONENT_LETTER_SOURCE_PACKAGE_REQUIREMENTS = {
          component: ::Packages::Debian::COMPONENT_REGEX,
          letter: LETTER_REGEX,
          source_package: PACKAGE_REGEX
        }.freeze
        FILE_NAME_REQUIREMENTS = {
          file_name: API::NO_SLASH_URL_PART_REGEX
        }.freeze

        included do
          feature_category :package_registry

          helpers ::API::Helpers::PackagesHelpers
          helpers ::API::Helpers::Packages::BasicAuthHelpers
          include ::API::Helpers::Authentication

          namespace 'packages/debian' do
            authenticate_with do |accept|
              accept.token_types(:personal_access_token, :deploy_token, :job_token)
                    .sent_through(:http_basic_auth)
            end

            helpers do
              def present_release_file
                distribution = ::Packages::Debian::DistributionsFinder.new(project_or_group, codename_or_suite: params[:distribution]).execute.last!

                present_carrierwave_file!(distribution.file)
              end
            end

            format :txt
            content_type :txt, 'text/plain'

            params do
              requires :distribution, type: String, desc: 'The Debian Codename', regexp: Gitlab::Regex.debian_distribution_regex
            end

            namespace 'dists/*distribution', requirements: DISTRIBUTION_REQUIREMENTS do
              # GET {projects|groups}/:id/packages/debian/dists/*distribution/Release.gpg
              desc 'The Release file signature' do
                detail 'This feature was introduced in GitLab 13.5'
              end

              route_setting :authentication, authenticate_non_public: true
              get 'Release.gpg' do
                not_found!
              end

              # GET {projects|groups}/:id/packages/debian/dists/*distribution/Release
              desc 'The unsigned Release file' do
                detail 'This feature was introduced in GitLab 13.5'
              end

              route_setting :authentication, authenticate_non_public: true
              get 'Release' do
                present_release_file
              end

              # GET {projects|groups}/:id/packages/debian/dists/*distribution/InRelease
              desc 'The signed Release file' do
                detail 'This feature was introduced in GitLab 13.5'
              end

              route_setting :authentication, authenticate_non_public: true
              get 'InRelease' do
                # Signature to be added in 7.3 of https://gitlab.com/groups/gitlab-org/-/epics/6057#note_582697034
                present_release_file
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

            params do
              requires :component, type: String, desc: 'The Debian Component', regexp: Gitlab::Regex.debian_component_regex
              requires :letter, type: String, desc: 'The Debian Classification (first-letter or lib-first-letter)'
              requires :source_package, type: String, desc: 'The Debian Source Package Name', regexp: Gitlab::Regex.debian_package_name_regex
            end

            namespace 'pool/:component/:letter/:source_package', requirements: COMPONENT_LETTER_SOURCE_PACKAGE_REQUIREMENTS do
              # GET {projects|groups}/:id/packages/debian/pool/:component/:letter/:source_package/:file_name
              params do
                requires :file_name, type: String, desc: 'The Debian File Name'
              end
              desc 'The package' do
                detail 'This feature was introduced in GitLab 13.5'
              end

              route_setting :authentication, authenticate_non_public: true
              get ':file_name', requirements: FILE_NAME_REQUIREMENTS do
                # https://gitlab.com/gitlab-org/gitlab/-/issues/5835#note_414103286
                'TODO File'
              end
            end
          end
        end
      end
    end
  end
end
