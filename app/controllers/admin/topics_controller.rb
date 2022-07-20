# frozen_string_literal: true

class Admin::TopicsController < Admin::ApplicationController
  include SendFileUpload
  include PreviewMarkdown

  before_action :topic, only: [:edit, :update, :destroy]

  feature_category :projects

  def index
    @topics = Projects::TopicsFinder.new(params: params.permit(:search)).execute.page(params[:page]).without_count
  end

  def new
    @topic = Projects::Topic.new
  end

  def edit
  end

  def create
    @topic = Projects::Topic.new(topic_params)

    if @topic.save
      redirect_to edit_admin_topic_path(@topic), notice: _('Topic %{topic_name} was successfully created.') % { topic_name: @topic.name }
    else
      render "new"
    end
  end

  def update
    if @topic.update(topic_params)
      redirect_to edit_admin_topic_path(@topic), notice: _('Topic was successfully updated.')
    else
      render "edit"
    end
  end

  def destroy
    @topic.destroy!

    redirect_to admin_topics_path,
                status: :found,
                notice: _('Topic %{topic_name} was successfully removed.') % { topic_name: @topic.title_or_name }
  end

  private

  def topic
    @topic ||= Projects::Topic.find(params[:id])
  end

  def topic_params
    params.require(:projects_topic).permit(allowed_topic_params)
  end

  def allowed_topic_params
    [
      :avatar,
      :description,
      :name,
      :title
    ]
  end
end
