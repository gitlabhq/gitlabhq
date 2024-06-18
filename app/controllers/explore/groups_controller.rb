# frozen_string_literal: true

class Explore::GroupsController < Explore::ApplicationController
  include GroupTree

  feature_category :groups_and_projects
  urgency :low

  MAX_QUERY_SIZE = 10_000

  def index
    render_group_tree GroupsFinder.new(current_user).execute.limit(MAX_QUERY_SIZE)
  end
end
