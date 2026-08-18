# frozen_string_literal: true

module API
  class CargoProjectPackages < ::API::Base
    helpers ::API::Helpers::PackagesHelpers
    helpers ::API::Helpers::Packages::BasicAuthHelpers
    include ::API::Helpers::Authentication

    DOWNLOAD_REQUIREMENTS = {
      package_name: ::API::NO_SLASH_URL_PART_REGEX,
      package_version: ::API::NO_SLASH_URL_PART_REGEX
    }.freeze

    # Constrain prefix segments to two normalized-name characters so the
    # :prefix_1/:prefix_2/:package_name route cannot shadow the three-segment
    # download route ending in literal `download`.
    INDEX_REQUIREMENTS = {
      prefix_1: /[a-z0-9_-]{2}/,
      prefix_2: /[a-z0-9_-]{2}/,
      first_char: /[a-z0-9-]/,
      package_name: ::API::NO_SLASH_URL_PART_REGEX
    }.freeze

    feature_category :package_registry
    urgency :low
    default_format :json

    authenticate_with do |accept|
      accept.token_types(:personal_access_token, :deploy_token, :job_token)
            .sent_through(:http_bearer_token)
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end

    resource :projects, requirements: ::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      helpers do
        def cargo_registry_url
          URI.join(
            Gitlab.config.gitlab.url,
            File.join(
              api_v4_projects_packages_path(id: user_project_with_read_package.id),
              "/packages/cargo"
            )
          )
        end
      end

      after_validation do
        require_packages_enabled!

        not_found! unless ::Feature.enabled?(:package_registry_cargo_support, user_project_with_read_package)

        authorize_read_package!(user_project_with_read_package)
      end

      namespace ':id/packages/cargo' do
        desc 'Get config.json' do
          detail 'This will be used by cargo for further requests'
          success code: 200
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' }
          ]
          tags %w[packages_cargo]
        end
        route_setting :authentication, authenticate_non_public: true
        route_setting :authorization, permissions: :read_cargo_package, boundary_type: :project,
          job_token_policies: :read_packages, allow_public_access_for_enabled_project_features: :package_registry
        get 'config.json' do
          {
            "dl" => cargo_registry_url,
            "api" => cargo_registry_url,
            "auth-required" => !user_project_with_read_package.public?
          }
        end

        helpers do
          def render_cargo_sparse_index!(package_name, path_prefix:)
            validate_cargo_index_path!(package_name, path_prefix)

            metadata = ::Packages::Cargo::MetadataFinder
              .new(user_project_with_read_package, package_name: package_name)
              .execute
              .to_a

            not_found!('Package') if metadata.empty?

            content_type 'text/plain'
            env['api.format'] = :binary
            ::Packages::Cargo::SparseIndexPresenter.new(metadata).body
          end

          # The path prefix is derived from the crate name by the Cargo client,
          # so a spec-compliant request always carries a prefix coherent with
          # the name (e.g. `se/rd/serde`). Reject incoherent paths such as
          # `zz/zz/serde`. Compared against the downcased name, never the
          # GitLab-normalized name, since the prefix mirrors the URL name segment.
          # https://doc.rust-lang.org/cargo/reference/registry-index.html#index-files
          def validate_cargo_index_path!(package_name, path_prefix)
            name = package_name.downcase

            expected =
              case name.length
              when 1 then %w[1]
              when 2 then %w[2]
              when 3 then ['3', name[0]]
              else [name[0, 2], name[2, 2]]
              end

            return if path_prefix == expected

            bad_request!('Request path does not match the Cargo index layout for this package name')
          end
        end

        desc 'Get the sparse index for a Cargo crate (1-character name)' do
          detail 'Returns newline-delimited JSON, one line per published version, most recently ' \
            'published first. Limited to the 500 most recently published versions.'
          success code: 200
          failure [
            { code: 400, message: 'Bad Request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          produces %w[text/plain]
          tags %w[packages_cargo]
        end
        params do
          requires :package_name, type: String, desc: 'The cargo package name'
        end
        route_setting :authentication, authenticate_non_public: true
        route_setting :authorization, permissions: :read_cargo_package, boundary_type: :project,
          job_token_policies: :read_packages, allow_public_access_for_enabled_project_features: :package_registry
        get '1/:package_name', requirements: INDEX_REQUIREMENTS do
          render_cargo_sparse_index!(params[:package_name], path_prefix: %w[1])
        end

        desc 'Get the sparse index for a Cargo crate (2-character name)' do
          detail 'Returns newline-delimited JSON, one line per published version, most recently ' \
            'published first. Limited to the 500 most recently published versions.'
          success code: 200
          failure [
            { code: 400, message: 'Bad Request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          produces %w[text/plain]
          tags %w[packages_cargo]
        end
        params do
          requires :package_name, type: String, desc: 'The cargo package name'
        end
        route_setting :authentication, authenticate_non_public: true
        route_setting :authorization, permissions: :read_cargo_package, boundary_type: :project,
          job_token_policies: :read_packages, allow_public_access_for_enabled_project_features: :package_registry
        get '2/:package_name', requirements: INDEX_REQUIREMENTS do
          render_cargo_sparse_index!(params[:package_name], path_prefix: %w[2])
        end

        desc 'Get the sparse index for a Cargo crate (3-character name)' do
          detail 'Returns newline-delimited JSON, one line per published version, most recently ' \
            'published first. Limited to the 500 most recently published versions.'
          success code: 200
          failure [
            { code: 400, message: 'Bad Request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          produces %w[text/plain]
          tags %w[packages_cargo]
        end
        params do
          requires :first_char, type: String, desc: 'First character of the cargo package name'
          requires :package_name, type: String, desc: 'The cargo package name'
        end
        route_setting :authentication, authenticate_non_public: true
        route_setting :authorization, permissions: :read_cargo_package, boundary_type: :project,
          job_token_policies: :read_packages, allow_public_access_for_enabled_project_features: :package_registry
        get '3/:first_char/:package_name', requirements: INDEX_REQUIREMENTS do
          render_cargo_sparse_index!(params[:package_name], path_prefix: ['3', params[:first_char]])
        end

        desc 'Get the sparse index for a Cargo crate (4+ character name)' do
          detail 'Returns newline-delimited JSON, one line per published version, most recently ' \
            'published first. Limited to the 500 most recently published versions.'
          success code: 200
          failure [
            { code: 400, message: 'Bad Request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          produces %w[text/plain]
          tags %w[packages_cargo]
        end
        params do
          requires :prefix_1, type: String, desc: 'First two characters of the cargo package name'
          requires :prefix_2, type: String, desc: 'Next two characters of the cargo package name'
          requires :package_name, type: String, desc: 'The cargo package name'
        end
        route_setting :authentication, authenticate_non_public: true
        route_setting :authorization, permissions: :read_cargo_package, boundary_type: :project,
          job_token_policies: :read_packages, allow_public_access_for_enabled_project_features: :package_registry
        get ':prefix_1/:prefix_2/:package_name', requirements: INDEX_REQUIREMENTS do
          render_cargo_sparse_index!(params[:package_name], path_prefix: [params[:prefix_1], params[:prefix_2]])
        end

        desc 'Download a Cargo crate' do
          detail 'This endpoint serves the .crate file for a given package name and version'
          success code: 200
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          produces %w[application/octet-stream]
          tags %w[packages_cargo]
        end
        params do
          requires :package_name, type: String, desc: 'The cargo package name'
          requires :package_version, type: String, desc: 'The cargo package version'
        end
        route_setting :authentication, authenticate_non_public: true
        route_setting :authorization, permissions: :download_cargo_package, boundary_type: :project,
          job_token_policies: :read_packages, allow_public_access_for_enabled_project_features: :package_registry
        get ':package_name/:package_version/download', requirements: DOWNLOAD_REQUIREMENTS do
          package = ::Packages::Cargo::PackageFinder.new(
            user_project_with_read_package,
            package_name: params[:package_name],
            package_version: params[:package_version]
          ).execute.last

          not_found!('Package') unless package

          package_file = package.package_files.installable.last

          not_found!('Package file') unless package_file

          track_package_event('pull_package', :cargo, project: user_project_with_read_package,
            namespace: user_project_with_read_package.namespace)

          present_package_file!(package_file)
        end

        desc 'Authorize a Cargo crate upload' do
          detail 'Workhorse authorize handshake performed before a cargo publish request'
          success code: 200
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          tags %w[packages_cargo]
          hidden true
        end
        route_setting :authentication, authenticate_non_public: true
        route_setting :authorization, skip_granular_token_authorization: :workhorse_pre_authorization,
          job_token_policies: :admin_packages
        put 'api/v1/crates/new/authorize' do
          authorize_upload!(user_project_with_read_package)

          content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE

          ::Packages::PackageFileUploader.workhorse_authorize(
            has_length: true,
            maximum_size: user_project_with_read_package.actual_limits.cargo_max_file_size
          )
        end
      end
    end
  end
end
