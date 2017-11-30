module IssuableActions
  extend ActiveSupport::Concern

  included do
    before_action :labels, only: [:show, :new, :edit]
    before_action :authorize_destroy_issuable!, only: :destroy
    before_action :authorize_admin_issuable!, only: :bulk_update
  end

  def show
    respond_to do |format|
      format.html
      format.json do
        render json: serializer.represent(issuable, serializer: params[:serializer])
      end
    end
  end

  def update
    @issuable = update_service.execute(issuable)

    respond_to do |format|
      format.html do
        recaptcha_check_with_fallback { render :edit }
      end

      format.json do
        render_entity_json
      end
    end

  rescue ActiveRecord::StaleObjectError
    render_conflict_response
  end

  def realtime_changes
    Gitlab::PollingInterval.set_header(response, interval: 3_000)

    response = {
      title: view_context.markdown_field(issuable, :title),
      title_text: issuable.title,
      description: view_context.markdown_field(issuable, :description),
      description_text: issuable.description,
      task_status: issuable.task_status
    }

    if issuable.edited?
      response[:updated_at] = issuable.updated_at
      response[:updated_by_name] = issuable.last_edited_by.name
      response[:updated_by_path] = user_path(issuable.last_edited_by)
    end

    render json: response
  end

  def destroy
    Issuable::DestroyService.new(project, current_user).execute(issuable)
    TodoService.new.destroy_issuable(issuable, current_user)

    name = issuable.human_class_name
    flash[:notice] = "The #{name} was successfully deleted."
    index_path = polymorphic_path([parent, issuable.class])

    respond_to do |format|
      format.html { redirect_to index_path }
      format.json do
        render json: {
          web_url: index_path
        }
      end
    end
  end

  def bulk_update
    result = Issuable::BulkUpdateService.new(project, current_user, bulk_update_params).execute(resource_name)
    quantity = result[:count]

    render json: { notice: "#{quantity} #{resource_name.pluralize(quantity)} updated" }
  end

  private

  def render_conflict_response
    respond_to do |format|
      format.html do
        @conflict = true
        render :edit
      end

      format.json do
        render json: {
          errors: [
            "Someone edited this #{issuable.human_class_name} at the same time you did. Please refresh your browser and make sure your changes will not unintentionally remove theirs."
          ]
        }, status: 409
      end
    end
  end

  def labels
    @labels ||= LabelsFinder.new(current_user, project_id: @project.id).execute
  end

  def authorize_destroy_issuable!
    unless can?(current_user, :"destroy_#{issuable.to_ability_name}", issuable)
      return access_denied!
    end
  end

  def authorize_admin_issuable!
    unless can?(current_user, :"admin_#{resource_name}", @project)
      return access_denied!
    end
  end

  def authorize_update_issuable!
    render_404 unless can?(current_user, :"update_#{resource_name}", issuable)
  end

  def bulk_update_params
    permitted_keys = [
      :issuable_ids,
      :assignee_id,
      :milestone_id,
      :state_event,
      :subscription_event,
      label_ids: [],
      add_label_ids: [],
      remove_label_ids: []
    ]

    if resource_name == 'issue'
      permitted_keys << { assignee_ids: [] }
    else
      permitted_keys.unshift(:assignee_id)
    end

    params.require(:update).permit(permitted_keys)
  end

  def resource_name
    @resource_name ||= controller_name.singularize
  end

  def render_entity_json
    if @issuable.valid?
      render json: serializer.represent(@issuable)
    else
      render json: { errors: @issuable.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def serializer
    raise NotImplementedError
  end

  def update_service
    raise NotImplementedError
  end

  def parent
    @project || @group
  end
end
