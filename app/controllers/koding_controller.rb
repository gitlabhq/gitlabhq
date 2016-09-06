class KodingController < ApplicationController
  before_action :check_integration!, :authenticate_user!, :reject_blocked!
  layout 'koding'

  def index
    path = File.join(Rails.root, 'doc/user/project/koding.md')
    @markdown = File.read(path)
  end

  private

  def check_integration!
    render_404 unless current_application_settings.koding_enabled?
  end
end
