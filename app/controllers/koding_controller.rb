class KodingController < ApplicationController
  before_action :check_integration!
  layout 'koding'

  def index
    path = File.join(Rails.root, 'doc/user/project/koding.md')
    @markdown = File.read(path)
  end

  private

  def check_integration!
    render_404 unless Gitlab::CurrentSettings.koding_enabled?
  end
end
