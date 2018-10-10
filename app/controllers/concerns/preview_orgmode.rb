# frozen_string_literal: true

module PreviewOrgmode
  extend ActiveSupport::Concern

  def preview_orgmode
    context = {
      current_user: (current_user if defined?(current_user)),

      # RelativeLinkFilter
      project:        project,
      commit:         @commit,
      project_wiki:   @project_wiki,
      ref:            @ref,
      requested_path: @path
    }

    html = Gitlab::OtherMarkup.render('preview.org', params[:text], context)
    html = Banzai.post_process(html, context)
    html = Hamlit::RailsHelpers.preserve(html)

    render json: {
      body: html
    }
  end
end
