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
          urgency :low

          helpers ::API::Helpers::PackagesHelpers
          helpers ::API::Helpers::Packages::BasicAuthHelpers
          include ::API::Helpers::Authentication

          helpers do
            params :shared_package_file_params do
              requires :distribution, type: String, desc: 'The Debian Codename or Suite', regexp: Gitlab::Regex.debian_distribution_regex, documentation: { example: 'my-distro' }
              requires :letter, type: String, desc: 'The Debian Classification (first-letter or lib-first-letter)', documentation: { example: 'a' }
              requires :package_name, type: String, desc: 'The Debian Source Package Name', regexp: Gitlab::Regex.debian_package_name_regex, documentation: { example: 'my-pkg' }
              requires :package_version, type: String, desc: 'The Debian Source Package Version', regexp: Gitlab::Regex.debian_version_regex, documentation: { example: '1.0.0' }
              requires :file_name, type: String, desc: 'The Debian File Name', documentation: { example: 'example_1.0.0~alpha2_amd64.deb' }
            end

            def distribution_from!(container)
              ::Packages::Debian::DistributionsFinder.new(container, codename_or_suite: params[:distribution]).execute.last!
            end

            def present_distribution_package_file!(project)
              not_found! unless params[:package_name].start_with?(params[:letter])

              package_file = distribution_from!(project).package_files.with_file_name(params[:file_name]).last!

              present_package_file!(package_file)
            end

            def present_index_file!(file_type)
              not_found!("Format #{params[:format]} is not supported") unless params[:format].nil?

              relation = "::Packages::Debian::#{project_or_group.class.name}ComponentFile".constantize

              relation = relation
                .preload_distribution
                .with_container(project_or_group)
                .with_codename_or_suite(params[:distribution])
                .with_component_name(params[:component])
                .with_file_type(file_type)
                .with_architecture_name(params[:architecture])
                .with_compression_type(nil)
                .order_created_asc

              # Empty component files are not persisted in DB
              no_content! if params[:file_sha256] == ::Packages::Debian::EMPTY_FILE_SHA256

              relation = relation.with_file_sha256(params[:file_sha256]) if params[:file_sha256]

              component_file = relation.last

              if component_file.nil? || component_file.empty?
                not_found! if params[:file_sha256] # asking for a non existing component file.
                no_content! # empty component files are not always persisted in DB
              end

              present_carrierwave_file!(component_file.file)
            end
          end

          rescue_from ArgumentError do |e|
            render_api_error!(e.message, 400)
          end

          rescue_from ActiveRecord::RecordInvalid do |e|
            render_api_error!(e.message, 400)
          end

          authenticate_with do |accept|
            accept.token_types(:personal_access_token_with_username, :deploy_token_with_username, :job_token_with_username)
                  .sent_through(:http_basic_auth)
          end

          format :txt
          content_type :txt, 'text/plain'

          params do
            requires :distribution, type: String, desc: 'The Debian Codename or Suite', regexp: Gitlab::Regex.debian_distribution_regex, documentation: { example: 'my-distro' }
          end

          namespace 'dists/*distribution', requirements: DISTRIBUTION_REQUIREMENTS do
            # GET {projects|groups}/:id/packages/debian/dists/*distribution/Release.gpg
            # https://wiki.debian.org/DebianRepository/Format#A.22Release.22_files
            desc 'The Release file signature' do
              detail 'This feature was introduced in GitLab 13.5'
              success code: 200
              failure [
                { code: 400, message: 'Bad Request' },
                { code: 401, message: 'Unauthorized' },
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not Found' }
              ]
              tags %w[debian_packages]
            end

            get 'Release.gpg' do
              distribution_from!(project_or_group).file_signature
            end

            # GET {projects|groups}/:id/packages/debian/dists/*distribution/Release
            # https://wiki.debian.org/DebianRepository/Format#A.22Release.22_files
            desc 'The unsigned Release file' do
              detail 'This feature was introduced in GitLab 13.5'
              success code: 200
              failure [
                { code: 400, message: 'Bad Request' },
                { code: 401, message: 'Unauthorized' },
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not Found' }
              ]
              tags %w[debian_packages]
            end

            get 'Release' do
              distribution = distribution_from!(project_or_group)
              present_carrierwave_file!(distribution.file)
            end

            # GET {projects|groups}/:id/packages/debian/dists/*distribution/InRelease
            # https://wiki.debian.org/DebianRepository/Format#A.22Release.22_files
            desc 'The signed Release file' do
              detail 'This feature was introduced in GitLab 13.5'
              success code: 200
              failure [
                { code: 400, message: 'Bad Request' },
                { code: 401, message: 'Unauthorized' },
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not Found' }
              ]
              tags %w[debian_packages]
            end

            get 'InRelease' do
              distribution = distribution_from!(project_or_group)
              present_carrierwave_file!(distribution.signed_file)
            end

            params do
              requires :component, type: String, desc: 'The Debian Component', regexp: Gitlab::Regex.debian_component_regex, documentation: { example: 'main' }
            end

            namespace ':component', requirements: COMPONENT_ARCHITECTURE_REQUIREMENTS do
              params do
                requires :architecture, type: String, desc: 'The Debian Architecture', regexp: Gitlab::Regex.debian_architecture_regex, documentation: { example: 'binary-amd64' }
              end

              namespace 'debian-installer/binary-:architecture' do
                # GET {projects|groups}/:id/packages/debian/dists/*distribution/:component/debian-installer/binary-:architecture/Packages
                # https://wiki.debian.org/DebianRepository/Format#A.22Packages.22_Indices
                desc 'The installer (udeb) binary files index' do
                  detail 'This feature was introduced in GitLab 15.4'
                  success [
                    { code: 200 },
                    { code: 202 }
                  ]
                  failure [
                    { code: 400, message: 'Bad Request' },
                    { code: 401, message: 'Unauthorized' },
                    { code: 403, message: 'Forbidden' },
                    { code: 404, message: 'Not Found' }
                  ]
                  tags %w[debian_packages]
                end

                get 'Packages' do
                  present_index_file!(:di_packages)
                end

                # GET {projects|groups}/:id/packages/debian/dists/*distribution/:component/debian-installer/binary-:architecture/by-hash/SHA256/:file_sha256
                # https://wiki.debian.org/DebianRepository/Format?action=show&redirect=RepositoryFormat#indices_acquisition_via_hashsums_.28by-hash.29
                desc 'The installer (udeb) binary files index by hash' do
                  detail 'This feature was introduced in GitLab 15.4'
                  success [
                    { code: 200 },
                    { code: 202 }
                  ]
                  failure [
                    { code: 400, message: 'Bad Request' },
                    { code: 401, message: 'Unauthorized' },
                    { code: 403, message: 'Forbidden' },
                    { code: 404, message: 'Not Found' }
                  ]
                  tags %w[debian_packages]
                end

                get 'by-hash/SHA256/:file_sha256' do
                  present_index_file!(:di_packages)
                end
              end

              namespace 'source', requirements: COMPONENT_ARCHITECTURE_REQUIREMENTS do
                # GET {projects|groups}/:id/packages/debian/dists/*distribution/:component/source/Sources
                # https://wiki.debian.org/DebianRepository/Format#A.22Sources.22_Indices
                desc 'The source files index' do
                  detail 'This feature was introduced in GitLab 15.4'
                  success [
                    { code: 200 },
                    { code: 202 }
                  ]
                  failure [
                    { code: 400, message: 'Bad Request' },
                    { code: 401, message: 'Unauthorized' },
                    { code: 403, message: 'Forbidden' },
                    { code: 404, message: 'Not Found' }
                  ]
                  tags %w[debian_packages]
                end

                get 'Sources' do
                  present_index_file!(:sources)
                end

                # GET {projects|groups}/:id/packages/debian/dists/*distribution/:component/source/by-hash/SHA256/:file_sha256
                # https://wiki.debian.org/DebianRepository/Format?action=show&redirect=RepositoryFormat#indices_acquisition_via_hashsums_.28by-hash.29
                desc 'The source files index by hash' do
                  detail 'This feature was introduced in GitLab 15.4'
                  success [
                    { code: 200 },
                    { code: 202 }
                  ]
                  failure [
                    { code: 400, message: 'Bad Request' },
                    { code: 401, message: 'Unauthorized' },
                    { code: 403, message: 'Forbidden' },
                    { code: 404, message: 'Not Found' }
                  ]
                  tags %w[debian_packages]
                end

                get 'by-hash/SHA256/:file_sha256' do
                  present_index_file!(:sources)
                end
              end

              params do
                requires :architecture, type: String, desc: 'The Debian Architecture', regexp: Gitlab::Regex.debian_architecture_regex, documentation: { example: 'binary-amd64' }
              end

              namespace 'binary-:architecture', requirements: COMPONENT_ARCHITECTURE_REQUIREMENTS do
                # GET {projects|groups}/:id/packages/debian/dists/*distribution/:component/binary-:architecture/Packages
                # https://wiki.debian.org/DebianRepository/Format#A.22Packages.22_Indices
                desc 'The binary files index' do
                  detail 'This feature was introduced in GitLab 13.5'
                  success [
                    { code: 200 },
                    { code: 202 }
                  ]
                  failure [
                    { code: 400, message: 'Bad Request' },
                    { code: 401, message: 'Unauthorized' },
                    { code: 403, message: 'Forbidden' },
                    { code: 404, message: 'Not Found' }
                  ]
                  tags %w[debian_packages]
                end

                get 'Packages' do
                  present_index_file!(:packages)
                end

                # GET {projects|groups}/:id/packages/debian/dists/*distribution/:component/binary-:architecture/by-hash/SHA256/:file_sha256
                # https://wiki.debian.org/DebianRepository/Format?action=show&redirect=RepositoryFormat#indices_acquisition_via_hashsums_.28by-hash.29
                desc 'The binary files index by hash' do
                  detail 'This feature was introduced in GitLab 15.4'
                  success [
                    { code: 200 },
                    { code: 202 }
                  ]
                  failure [
                    { code: 400, message: 'Bad Request' },
                    { code: 401, message: 'Unauthorized' },
                    { code: 403, message: 'Forbidden' },
                    { code: 404, message: 'Not Found' }
                  ]
                  tags %w[debian_packages]
                end

                get 'by-hash/SHA256/:file_sha256' do
                  present_index_file!(:packages)
                end
              end
            end
          end
        end
      end
    end
  end
end
