# frozen_string_literal: true
module API
  class GoProxy < ::API::Base
    helpers Gitlab::Golang
    helpers ::API::Helpers::PackagesHelpers

    GO_PROXY_TAGS = %w[go_proxy].freeze

    feature_category :package_registry
    urgency :low

    # basic semver, except case encoded (A => !a)
    MODULE_VERSION_REGEX = /v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([-.!a-z0-9]+))?(?:\+([-.!a-z0-9]+))?/

    MODULE_VERSION_REQUIREMENTS = { module_version: MODULE_VERSION_REGEX }.freeze

    content_type :txt, 'text/plain'

    before { require_packages_enabled! }

    helpers do
      def project
        user_project(action: :read_package)
      end

      def case_decode(str)
        # Converts "github.com/!azure" to "github.com/Azure"
        #
        # From `go help goproxy`:
        #
        # > To avoid problems when serving from case-sensitive file systems,
        # > the <module> and <version> elements are case-encoded, replacing
        # > every uppercase letter with an exclamation mark followed by the
        # > corresponding lower-case letter: github.com/Azure encodes as
        # > github.com/!azure.

        str.gsub(/![[:alpha:]]/) { |s| s[1..].upcase }
      end

      def find_module
        not_found! unless Feature.enabled?(:go_proxy, project)

        module_name = case_decode params[:module_name]
        bad_request_missing_attribute!('Module Name') if module_name.blank?

        mod = ::Packages::Go::ModuleFinder.new(project, module_name).execute

        not_found! unless mod

        mod
      end

      def find_version
        module_version = case_decode params[:module_version]
        ver = ::Packages::Go::VersionFinder.new(find_module).find(module_version)

        not_found! unless ver&.valid?

        ver

      rescue ArgumentError
        not_found!
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The project ID or full path of a project'
      requires :module_name, type: String, desc: 'The name of the Go module', coerce_with: ->(val) { CGI.unescape(val) }
    end
    route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true,
      authenticate_non_public: true
    route_setting :authorization, job_token_policies: :read_packages
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before do
        authorize_read_package!(project)
      end

      namespace ':id/packages/go/*module_name/@v' do
        desc 'List' do
          detail 'Get all tagged versions for a given Go module.'\
            'See `go help goproxy`, GET $GOPROXY/<module>/@v/list. This feature was introduced in GitLab 13.1.'
          tags GO_PROXY_TAGS
        end
        get 'list' do
          mod = find_module

          content_type 'text/plain'
          mod.versions.map { |t| t.name }.join("\n")
        end

        desc 'Version metadata' do
          detail 'Get all tagged versions for a given Go module.'\
            'See `go help goproxy`, GET $GOPROXY/<module>/@v/<version>.info. This feature was introduced in GitLab 13.1'
          success ::API::Entities::GoModuleVersion
          tags GO_PROXY_TAGS
        end
        params do
          requires :module_version, type: String, desc: 'The version of the Go module'
        end
        get ':module_version.info', requirements: MODULE_VERSION_REQUIREMENTS do
          ver = find_version

          present ::Packages::Go::ModuleVersionPresenter.new(ver), with: ::API::Entities::GoModuleVersion
        end

        desc 'Download module file' do
          detail 'Get the module file of a given module version.'\
            'See `go help goproxy`, GET $GOPROXY/<module>/@v/<version>.mod. This feature was introduced in GitLab 13.1.'
          tags GO_PROXY_TAGS
        end
        params do
          requires :module_version, type: String, desc: 'The version of the Go module'
        end
        get ':module_version.mod', requirements: MODULE_VERSION_REQUIREMENTS do
          ver = find_version

          content_type 'text/plain'
          ver.gomod
        end

        desc 'Download module source' do
          detail 'Get a zip of the source of the given module version.'\
            'See `go help goproxy`, GET $GOPROXY/<module>/@v/<version>.zip. This feature was introduced in GitLab 13.1.'
          tags GO_PROXY_TAGS
        end
        params do
          requires :module_version, type: String, desc: 'The version of the Go module'
        end
        get ':module_version.zip', requirements: MODULE_VERSION_REQUIREMENTS do
          ver = find_version

          content_type 'application/zip'
          env['api.format'] = :binary
          header['Content-Disposition'] =
            ActionDispatch::Http::ContentDisposition.format(disposition: 'attachment', filename: "#{ver.name}.zip")
          header['Content-Transfer-Encoding'] = 'binary'
          status :ok
          body ver.archive.string
        end
      end
    end
  end
end
