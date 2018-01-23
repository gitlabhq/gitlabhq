class IdeController < ApplicationController
  layout 'nav_only'

  before_action :check_ide_available!

  def index
  end

  private

  def check_ide_available!
    render_404 unless License.feature_available?(:ide)
  end
end
