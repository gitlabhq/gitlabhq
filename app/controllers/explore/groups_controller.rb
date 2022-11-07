# frozen_string_literal: true

class Explore::GroupsController < Explore::ApplicationController
  include GroupTree

  feature_category :subgroups
  urgency :low

  def index
    user = Feature.enabled?(:generic_explore_groups, current_user, type: :experiment) ? nil : current_user

    render_group_tree GroupsFinder.new(user).execute
  end
end
