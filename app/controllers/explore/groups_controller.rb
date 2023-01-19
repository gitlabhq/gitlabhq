# frozen_string_literal: true

class Explore::GroupsController < Explore::ApplicationController
  include GroupTree

  feature_category :subgroups
  urgency :low

  def index
    render_group_tree GroupsFinder.new(nil).execute
  end
end
