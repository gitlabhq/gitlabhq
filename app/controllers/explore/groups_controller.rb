# frozen_string_literal: true

class Explore::GroupsController < Explore::ApplicationController
  include GroupTree

  feature_category :subgroups

  def index
    render_group_tree GroupsFinder.new(current_user).execute
  end
end
