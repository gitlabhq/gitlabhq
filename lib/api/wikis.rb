# frozen_string_literal: true

module API
  class Wikis < ::API::Base
    helpers ::API::Helpers::WikisHelpers

    feature_category :wiki

    helpers do
      attr_reader :container

      params :common_wiki_page_params do
        optional :format,
          type: String,
          values: Wiki::MARKUPS.values.map(&:to_s),
          default: 'markdown',
          desc: 'Format of a wiki page. Available formats are markdown, rdoc, asciidoc and org'
      end
    end

    WIKI_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(slug: API::NO_SLASH_URL_PART_REGEX)

    ::API::Helpers::WikisHelpers.wiki_resource_kinds.each do |container_resource|
      resource container_resource, requirements: WIKI_ENDPOINT_REQUIREMENTS do
        after_validation do
          @container = Gitlab::Lazy.new { find_container(container_resource) }
        end

        desc 'Get a list of wiki pages' do
          success Entities::WikiPageBasic
        end
        params do
          optional :with_content, type: Boolean, default: false, desc: "Include pages' content"
        end
        get ':id/wikis' do
          authorize! :read_wiki, container

          entity = params[:with_content] ? Entities::WikiPage : Entities::WikiPageBasic

          present container.wiki.list_pages(load_content: params[:with_content]), with: entity
        end

        desc 'Get a wiki page' do
          success Entities::WikiPage
        end
        params do
          requires :slug, type: String, desc: 'The slug of a wiki page'
        end
        get ':id/wikis/:slug' do
          authorize! :read_wiki, container

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
          authorize! :create_wiki, container

          response = WikiPages::CreateService.new(container: container, current_user: current_user, params: params).execute
          page = response.payload[:page]

          if response.success?
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
          authorize! :create_wiki, container

          response = WikiPages::UpdateService
            .new(container: container, current_user: current_user, params: params)
            .execute(wiki_page)
          page = response.payload[:page]

          if response.success?
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
          authorize! :admin_wiki, container

          response = WikiPages::DestroyService
            .new(container: container, current_user: current_user)
            .execute(wiki_page)

          if response.success?
            no_content!
          else
            unprocessable_entity!(response.message)
          end
        end

        desc 'Upload an attachment to the wiki repository' do
          detail 'This feature was introduced in GitLab 11.3.'
          success Entities::WikiAttachment
        end
        params do
          requires :file, types: [Rack::Multipart::UploadedFile, ::API::Validations::Types::WorkhorseFile], desc: 'The attachment file to be uploaded'
          optional :branch, type: String, desc: 'The name of the branch'
        end
        post ":id/wikis/attachments" do
          authorize! :create_wiki, container

          result = ::Wikis::CreateAttachmentService.new(
            container: container,
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
end
