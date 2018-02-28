module API
  class Wikis < Grape::API
    helpers do
      params :wiki_page_params do
        requires :content, type: String, desc: 'Content of a wiki page'
        requires :title, type: String, desc: 'Title of a wiki page'
        optional :format,
          type: String,
          values: ProjectWiki::MARKUPS.values.map(&:to_s),
          default: 'markdown',
          desc: 'Format of a wiki page. Available formats are markdown, rdoc, and asciidoc'
      end
    end

    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      desc 'Get a list of wiki pages' do
        success Entities::WikiPageBasic
      end
      params do
        optional :with_content, type: Boolean, default: false, desc: "Include pages' content"
      end
      get ':id/wikis' do
        authorize! :read_wiki, user_project

        entity = params[:with_content] ? Entities::WikiPage : Entities::WikiPageBasic
        present user_project.wiki.pages, with: entity
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
        use :wiki_page_params
      end
      post ':id/wikis' do
        authorize! :create_wiki, user_project

        page = WikiPages::CreateService.new(user_project, current_user, params).execute

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
        use :wiki_page_params
      end
      put ':id/wikis/:slug' do
        authorize! :create_wiki, user_project

        page = WikiPages::UpdateService.new(user_project, current_user, params).execute(wiki_page)

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

        status 204
        WikiPages::DestroyService.new(user_project, current_user).execute(wiki_page)
      end
    end
  end
end
