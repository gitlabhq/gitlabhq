# frozen_string_literal: true

class Explore::GroupsController < Explore::ApplicationController
  include GroupTree

  feature_category :groups_and_projects
  urgency :low

  def index
    # For gitlab.com, including internal visibility groups here causes
    # a major performance issue: https://gitlab.com/gitlab-org/gitlab/-/issues/358944
    #
    # For self-hosted users, not including internal groups here causes
    # a lack of visibility: https://gitlab.com/gitlab-org/gitlab/-/issues/389041
    user = Gitlab.com? ? nil : current_user

    render_group_tree GroupsFinder.new(user).execute
  end
end
