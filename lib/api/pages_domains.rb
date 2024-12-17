# frozen_string_literal: true

module API
  class PagesDomains < ::API::Base
    include PaginationParams

    feature_category :pages

    PAGES_DOMAINS_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(domain: API::NO_SLASH_URL_PART_REGEX)

    before do
      authenticate!
    end

    after_validation do
      normalize_params_file_to_string
    end

    helpers do
      # rubocop: disable CodeReuse/ActiveRecord
      def find_pages_domain!
        user_project.pages_domains.find_by(domain: params[:domain]) || not_found!('PagesDomain')
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def pages_domain
        @pages_domain ||= find_pages_domain!
      end

      def normalize_params_file_to_string
        params.each do |k, v|
          if v.is_a?(Hash) && v.key?(:tempfile)
            params[k] = v[:tempfile].to_a.join('')
          end
        end
      end
    end

    resource :pages do
      before do
        require_pages_config_enabled!
        authenticated_with_can_read_all_resources!
      end

      desc "Get all pages domains" do
        success Entities::PagesDomainBasic
      end
      params do
        use :pagination
      end
      get "domains" do
        present paginate(PagesDomain.all), with: Entities::PagesDomainBasic
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project owned by the authenticated user'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before do
        require_pages_enabled!
      end

      desc 'Get all pages domains' do
        success Entities::PagesDomain
        tags %w[pages_domains]
        is_array true
      end
      params do
        use :pagination
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get ":id/pages/domains" do
        authorize! :read_pages, user_project

        present paginate(user_project.pages_domains.order(:domain)), with: Entities::PagesDomain
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Get a single pages domain' do
        success Entities::PagesDomain
      end
      params do
        requires :domain, type: String, desc: 'The domain'
      end
      get ":id/pages/domains/:domain", requirements: PAGES_DOMAINS_ENDPOINT_REQUIREMENTS do
        authorize! :read_pages, user_project

        present pages_domain, with: Entities::PagesDomain
      end

      desc 'Create a new pages domain' do
        success Entities::PagesDomain
      end
      params do
        requires :domain, type: String, desc: 'The domain'
        # rubocop:todo Scalability/FileUploads
        # TODO: remove rubocop disable - https://gitlab.com/gitlab-org/gitlab/issues/14960
        optional :certificate, types: [File, String], desc: 'The certificate', as: :user_provided_certificate
        optional :key, types: [File, String], desc: 'The key', as: :user_provided_key
        optional :auto_ssl_enabled, allow_blank: false, type: Boolean, default: false,
          desc: "Enables automatic generation of SSL certificates issued by Let's Encrypt for custom domains."
        # rubocop:enable Scalability/FileUploads
        all_or_none_of :user_provided_certificate, :user_provided_key
      end
      post ":id/pages/domains" do
        authorize! :update_pages, user_project

        pages_domain_params = declared(params, include_parent_namespaces: false)

        pages_domain = ::Pages::Domains::CreateService.new(user_project, current_user, pages_domain_params).execute

        if pages_domain.persisted?
          present pages_domain, with: Entities::PagesDomain
        else
          render_validation_error!(pages_domain)
        end
      end

      desc 'Updates a pages domain'
      params do
        requires :domain, type: String, desc: 'The domain'
        # rubocop:todo Scalability/FileUploads
        # TODO: remove rubocop disable - https://gitlab.com/gitlab-org/gitlab/issues/14960
        optional :certificate, types: [File, String], desc: 'The certificate', as: :user_provided_certificate
        optional :key, types: [File, String], desc: 'The key', as: :user_provided_key
        optional :auto_ssl_enabled, allow_blank: true, type: Boolean,
          desc: "Enables automatic generation of SSL certificates issued by Let's Encrypt for custom domains."
        # rubocop:enable Scalability/FileUploads
      end
      put ":id/pages/domains/:domain", requirements: PAGES_DOMAINS_ENDPOINT_REQUIREMENTS do
        authorize! :update_pages, user_project

        pages_domain_params = declared(params, include_parent_namespaces: false, include_missing: false)

        # Remove empty private key if certificate is not empty.
        if pages_domain_params[:user_provided_certificate] && !pages_domain_params[:user_provided_key]
          pages_domain_params.delete(:user_provided_key)
        end

        service = ::Pages::Domains::UpdateService.new(user_project, current_user, pages_domain_params)

        if service.execute(pages_domain)
          present pages_domain, with: Entities::PagesDomain
        else
          render_validation_error!(pages_domain)
        end
      end

      desc 'Verify a pages domain' do
        success Entities::PagesDomain
      end
      params do
        requires :domain, type: String, desc: 'The domain to verify'
      end
      put ":id/pages/domains/:domain/verify", requirements: PAGES_DOMAINS_ENDPOINT_REQUIREMENTS do
        authorize! :update_pages, user_project

        pages_domain = find_pages_domain!
        result = ::VerifyPagesDomainService.new(pages_domain).execute

        if result[:status] == :success
          present pages_domain, with: Entities::PagesDomain
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      desc 'Delete a pages domain'
      params do
        requires :domain, type: String, desc: 'The domain'
      end
      delete ":id/pages/domains/:domain", requirements: PAGES_DOMAINS_ENDPOINT_REQUIREMENTS do
        authorize! :update_pages, user_project

        ::Pages::Domains::DeleteService.new(user_project, current_user).execute(pages_domain)

        no_content!
      end
    end
  end
end
