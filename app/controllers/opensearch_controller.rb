class OpensearchController < ApplicationController
  skip_before_action :authenticate_user!, :reject_blocked!

  def index
    render 'shared/opensearch.xml', locals: {
      gitlab_host: Gitlab.config.gitlab.host,
      favicon_path: ActionController::Base.helpers.asset_path('favicon.ico'),
      search_url: URI.unescape(search_url(search: '{searchTerms}')),
      description: "Search #{Appearance.first.title.truncate(1010)} GitLab",
      long_name: "#{Appearance.first.title.truncate(34)} GitLab search"
    }
  end
end
