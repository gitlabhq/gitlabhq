# frozen_string_literal: true

class Admin::Topics::AvatarsController < Admin::ApplicationController
  feature_category :groups_and_projects

  def destroy
    @topic = Projects::Topic.find(params.permit(:topic_id)[:topic_id])

    @topic.remove_avatar!
    @topic.save

    redirect_to edit_admin_topic_path(@topic), status: :found
  end
end
