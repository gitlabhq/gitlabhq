# frozen_string_literal: true

module API
  class Markdown < ::API::Base
    before { authenticate! if Feature.enabled?(:authenticate_markdown_api, type: :ops) }

    feature_category :team_planning

    params do
      requires :text, type: String, desc: "The Markdown text to render"
      optional :gfm, type: Boolean, desc: "Render text using GitLab Flavored Markdown. Default is false"
      optional :project, type: String, desc: "Use project as a context when creating references using GitLab Flavored Markdown"
    end
    resource :markdown do
      desc "Render an arbitrary Markdown document" do
        detail "This feature was introduced in GitLab 11.0."
        success ::API::Entities::Markdown
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' }
        ]
        tags %w[markdown]
      end
      post do
        context = { only_path: false, current_user: current_user }
        context[:pipeline] = params[:gfm] ? :full : :plain_markdown

        if params[:project]
          project = Project.find_by_full_path(params[:project])

          not_found!("Project") unless can?(current_user, :read_project, project)

          context[:project] = project
        else
          context[:skip_project_check] = true
        end

        # Disable comments in markdown for IE browsers because comments in IE
        # could allow script execution.
        browser = Browser.new(headers['User-Agent'])
        context[:allow_comments] = !browser.ie?

        present({ html: Banzai.render_and_post_process(params[:text], context) }, with: Entities::Markdown)
      end
    end
  end
end
