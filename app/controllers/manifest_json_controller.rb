class ManifestJsonController < ApplicationController
  skip_before_action :authenticate_user!, :reject_blocked!

  def index
    puts Gitlab.config.gitlab.inspect
    render 'shared/manifest.json', locals: {
      homepage_url: Gitlab.config.gitlab.url,
      icons: {
        '32' => ActionController::Base.helpers.asset_path('favicon.ico'),
        '128' => ActionController::Base.helpers.asset_path('gitlab_logo.png')
      }
    }
  end
end
