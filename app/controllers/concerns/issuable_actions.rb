# frozen_string_literal: true

module IssuableActions
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize
  include Gitlab::Cache::Helpers
  include SpammableActions::AkismetMarkAsSpamAction
  include SpammableActions::CaptchaCheck::HtmlFormatActionsSupport
  include SpammableActions::CaptchaCheck::JsonFormatActionsSupport

  included do
    before_action :authorize_destroy_issuable!, only: :destroy
    before_action :check_destroy_confirmation!, only: :destroy
    before_action :authorize_admin_issuable!, only: :bulk_update
    before_action :set_application_context!, only: :show
  end

  def show
    respond_to do |format|
      format.html do
        @issuable_sidebar = serializer.represent(issuable, serializer: 'sidebar') # rubocop:disable Gitlab/ModuleWithInstanceVariables
        render 'show'
      end

      format.json do
        render json: serializer.represent(issuable, serializer: params[:serializer])
      end
    end
  end

  def update
    updated_issuable = update_service.execute(issuable)
    # NOTE: We only assign the instance variable on this line, and use the local variable
    # everywhere else in the method, to avoid having to add multiple `rubocop:disable` comments.
    @issuable = updated_issuable # rubocop:disable Gitlab/ModuleWithInstanceVariables

    # NOTE: This check for `is_a?(Spammable)` is necessary because not all
    # possible `issuable` types implement Spammable. Once they all implement Spammable,
    # this check can be removed.
    if updated_issuable.is_a?(Spammable)
      respond_to do |format|
        format.html do
          if updated_issuable.valid?
            # NOTE: This redirect is intentionally only performed in the case where the valid updated
            # issuable is a spammable, and intentionally is not performed below in the
            # valid non-spammable case. This preserves the legacy behavior of this action.
            redirect_to spammable_path
          else
            with_captcha_check_html_format(spammable: spammable) { render :edit }
          end
        end

        format.json do
          with_captcha_check_json_format(spammable: spammable) { render_entity_json }
        end
      end
    else
      respond_to do |format|
        format.html do
          render :edit
        end

        format.json do
          render_entity_json
        end
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
      task_completion_status: issuable.task_completion_status,
      lock_version: issuable.lock_version
    }

    if issuable.edited?
      response[:updated_at] = issuable.last_edited_at.to_time.iso8601
      response[:updated_by_name] = issuable.last_edited_by.name
      response[:updated_by_path] = user_path(issuable.last_edited_by)
    end

    render json: response
  end

  def destroy
    Issuable::DestroyService.new(container: issuable.project, current_user: current_user).execute(issuable)

    name = issuable.human_class_name
    flash[:notice] = "The #{name} was successfully deleted."
    index_path = polymorphic_path([parent, issuable.class])

    respond_to do |format|
      format.html { redirect_to index_path, status: :see_other }
      format.json do
        render json: {
          web_url: index_path
        }
      end
    end
  end

  def check_destroy_confirmation!
    return true if params[:destroy_confirm]

    error_message = "Destroy confirmation not provided for #{issuable.human_class_name}"
    exception = RuntimeError.new(error_message)
    Gitlab::ErrorTracking.track_exception(
      exception,
      project_path: issuable.project.full_path,
      issuable_type: issuable.class.name,
      issuable_id: issuable.id
    )

    index_path = polymorphic_path([parent, issuable.class])

    respond_to do |format|
      format.html do
        flash[:notice] = error_message
        redirect_to index_path
      end
      format.json do
        render json: { errors: error_message }, status: :unprocessable_entity
      end
    end
  end

  def bulk_update
    result = Issuable::BulkUpdateService.new(parent, current_user, bulk_update_params).execute(resource_name)

    if result.success?
      quantity = result.payload[:count]
      render json: { notice: "#{quantity} #{resource_name.pluralize(quantity)} updated" }
    elsif result.error?
      render json: { errors: result.message }, status: result.http_status
    end
  end

  def discussions
    finder = Issuable::DiscussionsListService.new(current_user, issuable, finder_params_for_issuable)
    discussion_notes = finder.execute

    yield discussion_notes if block_given?

    if finder.paginator.present? && finder.paginator.has_next_page?
      response.headers['X-Next-Page-Cursor'] = finder.paginator.cursor_for_next_page
    end

    case issuable
    when MergeRequest, Issue
      if stale?(etag: [discussion_cache_context, discussion_notes])
        render json: discussion_serializer.represent(discussion_notes, context: self)
      end
    else
      render json: discussion_serializer.represent(discussion_notes, context: self)
    end
  end

  private

  def notes_filter
    notes_filter_param = params[:notes_filter]&.to_i

    # GitLab Geo does not expect database UPDATE or INSERT statements to happen
    # on GET requests.
    # This is just a fail-safe in case notes_filter is sent via GET request in GitLab Geo.
    # In some cases, we also force the filter to not be persisted with the `persist_filter` param
    if Gitlab::Database.read_only? || params[:persist_filter] == 'false'
      notes_filter_param || current_user&.notes_filter_for(issuable)
    else
      current_user&.set_notes_filter(notes_filter_param, issuable) || notes_filter_param
    end
  end
  strong_memoize_attr :notes_filter

  def discussion_cache_context
    [current_user&.cache_key, project.team.human_max_access(current_user&.id), 'v2'].join(':')
  end

  def discussion_serializer
    DiscussionSerializer.new(project: project, noteable: issuable, current_user: current_user,
      note_entity: ProjectNoteEntity)
  end

  def render_conflict_response
    respond_to do |format|
      format.html do
        @conflict = true # rubocop:disable Gitlab/ModuleWithInstanceVariables
        render :edit
      end

      format.json do
        render json: {
          errors: [
            <<~HEREDOC.squish
            Someone edited this #{issuable.human_class_name} at the same time you did.
            Please refresh your browser and make sure your changes will not unintentionally remove theirs.
            HEREDOC
          ]
        }, status: :conflict
      end
    end
  end

  def authorize_destroy_issuable!
    access_denied! unless can?(current_user, :"destroy_#{issuable.to_ability_name}", issuable)
  end

  def authorize_admin_issuable!
    access_denied! unless can?(current_user, :"admin_#{resource_name}", parent)
  end

  def authorize_update_issuable!
    render_404 unless can?(current_user, :"update_#{resource_name}", issuable)
  end

  def set_application_context!
    # no-op. The logic is defined in EE module.
  end

  def bulk_update_params
    clean_bulk_update_params(
      params.require(:update).permit(bulk_update_permitted_keys)
    )
  end

  def clean_bulk_update_params(permitted_params)
    permitted_params.delete_if do |k, v|
      next if k == :issuable_ids

      if v.is_a?(Array)
        v.compact.empty?
      else
        v.blank?
      end
    end
  end

  def bulk_update_permitted_keys
    [
      :issuable_ids,
      :assignee_id,
      :milestone_id,
      :state_event,
      :subscription_event,
      :confidential,
      { assignee_ids: [],
        add_label_ids: [],
        remove_label_ids: [] }
    ]
  end

  def resource_name
    @resource_name ||= controller_name.singularize
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def render_entity_json
    if @issuable.valid?
      render json: serializer.represent(@issuable)
    else
      render json: { errors: @issuable.errors.full_messages }, status: :unprocessable_entity
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def serializer
    raise NotImplementedError
  end

  def update_service
    raise NotImplementedError
  end

  def parent
    @project || @group # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  def finder_params_for_issuable
    {
      notes_filter: notes_filter,
      cursor: params[:cursor],
      per_page: params[:per_page]
    }
  end
end

IssuableActions.prepend_mod_with('IssuableActions')
