# frozen_string_literal: true

module API
  class Wikis < Grape::API
    helpers do
      def commit_params(attrs)
        # In order to avoid service disruption this can work with an old workhorse without the acceleration
        # the first branch of this if must be removed when we drop support for non accelerated uploads
        if attrs[:file].is_a?(Hash)
          {
            file_name: attrs[:file][:filename],
            file_content: attrs[:file][:tempfile].read,
            branch_name: attrs[:branch]
          }
        else
          {
            file_name: attrs[:file].original_filename,
            file_content: attrs[:file].read,
            branch_name: attrs[:branch]
          }
        end
      end

      params :common_wiki_page_params do
        optional :format,
          type: String,
          values: Wiki::MARKUPS.values.map(&:to_s),
          default: 'markdown',
          desc: 'Format of a wiki page. Available formats are markdown, rdoc, asciidoc and org'
      end
    end

    WIKI_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(slug: API::NO_SLASH_URL_PART_REGEX)

    resource :projects, requirements: WIKI_ENDPOINT_REQUIREMENTS do
      desc 'Get a list of wiki pages' do
        success Entities::WikiPageBasic
      end
      params do
        optional :with_content, type: Boolean, default: false, desc: "Include pages' content"
      end
      get ':id/wikis' do
        authorize! :read_wiki, user_project

        entity = params[:with_content] ? Entities::WikiPage : Entities::WikiPageBasic

        present user_project.wiki.list_pages(load_content: params[:with_content]), with: entity
      end

      desc 'Get a wiki page' do
        success Entities::WikiPage
      end
      params do
        requires :slug, type: String, desc: 'The slug of a wiki page'
      end
      get ':id/wikis/:slug' do
        authorize! :read_wiki, user_project

        present wiki_page, with: Entities::WikiPage
      end

      desc 'Create a wiki page' do
        success Entities::WikiPage
      end
      params do
        requires :title, type: String, desc: 'Title of a wiki page'
        requires :content, type: String, desc: 'Content of a wiki page'
        use :common_wiki_page_params
      end
      post ':id/wikis' do
        authorize! :create_wiki, user_project

        page = WikiPages::CreateService.new(container: user_project, current_user: current_user, params: params).execute

        if page.valid?
          present page, with: Entities::WikiPage
        else
          render_validation_error!(page)
        end
      end

      desc 'Update a wiki page' do
        success Entities::WikiPage
      end
      params do
        optional :title, type: String, desc: 'Title of a wiki page'
        optional :content, type: String, desc: 'Content of a wiki page'
        use :common_wiki_page_params
        at_least_one_of :content, :title, :format
      end
      put ':id/wikis/:slug' do
        authorize! :create_wiki, user_project

        page = WikiPages::UpdateService.new(container: user_project, current_user: current_user, params: params).execute(wiki_page)

        if page.valid?
          present page, with: Entities::WikiPage
        else
          render_validation_error!(page)
        end
      end

      desc 'Delete a wiki page'
      params do
        requires :slug, type: String, desc: 'The slug of a wiki page'
      end
      delete ':id/wikis/:slug' do
        authorize! :admin_wiki, user_project

        WikiPages::DestroyService.new(container: user_project, current_user: current_user).execute(wiki_page)

        no_content!
      end

      desc 'Upload an attachment to the wiki repository' do
        detail 'This feature was introduced in GitLab 11.3.'
        success Entities::WikiAttachment
      end
      params do
        requires :file, types: [::API::Validations::Types::SafeFile, ::API::Validations::Types::WorkhorseFile], desc: 'The attachment file to be uploaded'
        optional :branch, type: String, desc: 'The name of the branch'
      end
      post ":id/wikis/attachments" do
        authorize! :create_wiki, user_project

        result = ::Wikis::CreateAttachmentService.new(
          container: user_project,
          current_user: current_user,
          params: commit_params(declared_params(include_missing: false))
        ).execute

        if result[:status] == :success
          status(201)
          present OpenStruct.new(result[:result]), with: Entities::WikiAttachment
        else
          render_api_error!(result[:message], 400)
        end
      end
    end
  end
end
