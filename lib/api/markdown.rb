# frozen_string_literal: true

module API
  class Markdown < ::API::Base
    feature_category :not_owned

    params do
      requires :text, type: String, desc: "The markdown text to render"
      optional :gfm, type: Boolean, desc: "Render text using GitLab Flavored Markdown"
      optional :project, type: String, desc: "The full path of a project to use as the context when creating references using GitLab Flavored Markdown"
    end
    resource :markdown do
      desc "Render markdown text" do
        detail "This feature was introduced in GitLab 11.0."
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

        { html: Banzai.render_and_post_process(params[:text], context) }
      end
    end
  end
end
