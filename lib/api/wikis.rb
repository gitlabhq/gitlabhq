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
          values: Wiki::VALID_USER_MARKUPS.keys.map(&:to_s),
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
          failure [
            { code: 404, message: 'Not found' }
          ]
          tags %w[wikis]
          is_array true
        end
        params do
          optional :with_content, type: Boolean, default: false, desc: "Include pages' content"
        end
        get ':id/wikis', urgency: :low do
          authorize! :read_wiki, container

          entity = params[:with_content] ? Entities::WikiPage : Entities::WikiPageBasic

          options = {
            with: entity,
            current_user: current_user
          }

          present container.wiki.list_pages(load_content: params[:with_content]), options
        end

        desc 'Get a wiki page' do
          success Entities::WikiPage
          failure [
            { code: 404, message: 'Not found' }
          ]
          tags %w[wikis]
        end
        params do
          requires :slug, type: String, desc: 'The slug of a wiki page'
          optional :version, type: String, desc: 'The version hash of a wiki page'
          optional :render_html, type: Boolean, default: false, desc: 'Render content to HTML'
        end
        get ':id/wikis/:slug', requirements: { slug: /.+/ }, urgency: :low do
          authorize! :read_wiki, container

          options = {
            with: Entities::WikiPage,
            render_html: params[:render_html],
            current_user: current_user
          }

          present wiki_page(params[:version]), options
        end

        desc 'Create a wiki page' do
          success Entities::WikiPage
          failure [
            { code: 400, message: 'Validation error' },
            { code: 404, message: 'Not found' },
            { code: 422, message: 'Unprocessable entity' }
          ]
          tags %w[wikis]
        end
        params do
          requires :title, type: String, desc: 'Title of a wiki page'
          optional :front_matter, type: Hash do
            optional :title, type: String, desc: 'Front matter title of a wiki page'
          end
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
          failure [
            { code: 400, message: 'Validation error' },
            { code: 404, message: 'Not found' },
            { code: 422, message: 'Unprocessable entity' }
          ]
          tags %w[wikis]
        end
        params do
          optional :title, type: String, desc: 'Title of a wiki page'
          optional :front_matter, type: Hash do
            optional :title, type: String, desc: 'Front matter title of a wiki page'
          end
          optional :content, type: String, desc: 'Content of a wiki page'
          use :common_wiki_page_params
          at_least_one_of :content, :title, :format
        end
        put ':id/wikis/:slug', requirements: { slug: /.+/ } do
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

        desc 'Delete a wiki page' do
          success code: 204
          failure [
            { code: 400, message: 'Validation error' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[wikis]
        end
        params do
          requires :slug, type: String, desc: 'The slug of a wiki page'
        end
        delete ':id/wikis/:slug', requirements: { slug: /.+/ } do
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
          failure [
            { code: 404, message: 'Not found' }
          ]
          tags %w[wikis]
        end
        params do
          requires :file, types: [Rack::Multipart::UploadedFile, ::API::Validations::Types::WorkhorseFile], desc: 'The attachment file to be uploaded', documentation: { type: 'file' }
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
            present result[:result], with: Entities::WikiAttachment
          else
            render_api_error!(result[:message], 400)
          end
        end
      end
    end
  end
end
