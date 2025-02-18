# frozen_string_literal: true

class Admin::TopicsController < Admin::ApplicationController
  include SendFileUpload
  include PreviewMarkdown

  before_action :topic, only: [:edit, :update, :destroy]

  feature_category :groups_and_projects

  def index
    @topics = Projects::TopicsFinder.new(
      params: params.permit(:search),
      organization_id: organization_id
    ).execute.page(pagination_params[:page]).without_count
  end

  def new
    @topic = Projects::Topic.new
  end

  def edit; end

  def create
    @topic = Projects::Topic.new(topic_params)

    if @topic.save
      redirect_to admin_topics_path,
        notice: format(_('Topic %{topic_name} was successfully created.'), topic_name: @topic.name)
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
      notice: format(_('Topic %{topic_name} was successfully removed.'), topic_name: @topic.title_or_name)
  end

  def merge
    source_topic = Projects::Topic.find(merge_params[:source_topic_id])
    target_topic = Projects::Topic.find(merge_params[:target_topic_id])

    response = ::Topics::MergeService.new(source_topic, target_topic).execute
    return render status: :bad_request, json: { type: :alert, message: response.message } if response.error?

    message = _('Topic %{source_topic} was successfully merged into topic %{target_topic}.')
    flash[:toast] = format(message, source_topic: source_topic.name, target_topic: target_topic.name)
    redirect_to admin_topics_path, status: :found
  end

  private

  def topic
    @topic ||= Projects::Topic.find_by_id_and_organization_id!(params.permit(:id)[:id], organization_id)
  end

  def topic_params
    params.require(:projects_topic).permit(allowed_topic_params).merge({ organization_id: organization_id })
  end

  def allowed_topic_params
    [
      :avatar,
      :description,
      :name,
      :title
    ]
  end

  def merge_params
    params.permit([:source_topic_id, :target_topic_id])
  end

  def organization_id
    ::Current.organization&.id
  end
end
