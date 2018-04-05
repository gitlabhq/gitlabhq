class Groups::EpicsController < Groups::ApplicationController
  include IssuableActions
  include IssuableCollections
  include ToggleAwardEmoji
  include RendersNotes

  before_action :check_epics_available!
  before_action :epic, except: [:index, :create]
  before_action :set_issuables_index, only: :index
  before_action :authorize_update_issuable!, only: :update
  before_action :authorize_create_epic!, only: [:create]

  skip_before_action :labels

  def index
    set_default_state
    @epics = @issuables

    respond_to do |format|
      format.html
      format.json do
        render json: serializer.represent(@epics)
      end
    end
  end

  def create
    @epic = ::Epics::CreateService.new(@group, current_user, epic_params).execute

    if @epic.persisted?
      render json: {
        web_url: group_epic_path(@group, @epic)
      }
    else
      head :unprocessable_entity
    end
  end

  private

  def pagination_disabled?
    request.format.json?
  end

  def epic
    @issuable = @epic ||= @group.epics.find_by(iid: params[:epic_id] || params[:id])

    return render_404 unless can?(current_user, :read_epic, @epic)

    @epic
  end
  alias_method :issuable, :epic
  alias_method :awardable, :epic

  def epic_params
    params.require(:epic).permit(*epic_params_attributes)
  end

  def epic_params_attributes
    [
      :title,
      :description,
      :start_date,
      :end_date,
      label_ids: []
    ]
  end

  def serializer
    EpicSerializer.new(current_user: current_user)
  end

  def discussion_serializer
    DiscussionSerializer.new(project: nil, noteable: issuable, current_user: current_user, note_entity: EpicNoteEntity)
  end

  def update_service
    ::Epics::UpdateService.new(@group, current_user, epic_params)
  end

  def finder_type
    EpicsFinder
  end

  def collection_type
    @collection_type ||= 'Epic'
  end

  # we don't support custom sorting for epics and therefore don't want to use the issuable_sort cookie
  def set_sort_order_from_cookie
  end

  def preload_for_collection
    @preload_for_collection ||= [:group, :author]
  end

  # we need to override the default state which is opened for now because we don't have
  # states for epics and need all as default for navigation to work correctly (#4017)
  def set_default_state
    params[:state] = 'all'
  end

  def authorize_create_epic!
    return render_404 unless can?(current_user, :create_epic, group)
  end

  def filter_params
    super.merge(start_date: params[:start_date], end_date: params[:end_date])
  end
end
