class Groups::LabelsController < Groups::ApplicationController
  include ToggleSubscriptionAction

  before_action :label, only: [:edit, :update, :destroy]
  before_action :authorize_admin_labels!, only: [:new, :create, :edit, :update, :destroy]
  before_action :save_previous_label_path, only: [:edit]

  respond_to :html

  def index
    respond_to do |format|
      format.html do
        @labels = @group.labels.page(params[:page])
      end

      format.json do
        available_labels = LabelsFinder.new(
          current_user,
          group_id: @group.id,
          only_group_labels: params[:only_group_labels],
          include_ancestor_groups: params[:include_ancestor_groups],
          include_descendant_groups: params[:include_descendant_groups]
        ).execute

        render json: LabelSerializer.new.represent_appearance(available_labels)
      end
    end
  end

  def new
    @label = @group.labels.new
    @previous_labels_path = previous_labels_path
  end

  def create
    @label = Labels::CreateService.new(label_params).execute(group: group)

    respond_to do |format|
      format.html do
        if @label.valid?
          redirect_to group_labels_path(@group)
        else
          render :new
        end
      end

      format.json do
        render json: LabelSerializer.new.represent_appearance(@label)
      end
    end
  end

  def edit
    @previous_labels_path = previous_labels_path
  end

  def update
    @label = Labels::UpdateService.new(label_params).execute(@label)

    if @label.valid?
      redirect_back_or_group_labels_path
    else
      render :edit
    end
  end

  def destroy
    @label.destroy

    respond_to do |format|
      format.html do
        redirect_to group_labels_path(@group), status: 302, notice: "#{@label.name} deleted permanently"
      end
      format.js
    end
  end

  protected

  def authorize_admin_labels!
    return render_404 unless can?(current_user, :admin_label, @group)
  end

  def authorize_read_labels!
    return render_404 unless can?(current_user, :read_label, @group)
  end

  def label
    @label ||= @group.labels.find(params[:id])
  end
  alias_method :subscribable_resource, :label

  def subscribable_project
    nil
  end

  def label_params
    params.require(:label).permit(:title, :description, :color)
  end

  def redirect_back_or_group_labels_path(options = {})
    redirect_to previous_labels_path, options
  end

  def previous_labels_path
    session.fetch(:previous_labels_path, fallback_path)
  end

  def fallback_path
    group_labels_path(@group)
  end

  def save_previous_label_path
    session[:previous_labels_path] = URI(request.referer || '').path
  end
end
