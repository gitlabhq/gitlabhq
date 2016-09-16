class Groups::LabelsController < Groups::ApplicationController
  before_action :label, only: [:edit, :update, :destroy, :toggle_subscription]
  before_action :authorize_admin_labels!, only: [:new, :create, :edit, :update, :generate, :destroy]

  respond_to :html

  def index
    @global_labels = @group.labels.unprioritized.with_type(:global_label).page(params[:page])
    @labels = @group.labels.unprioritized.with_type(:group_label).page(params[:page])
  end

  def new
    @label = @group.labels.new
  end

  def create
    service = Labels::CreateService.new(@group, current_user, label_params.merge(label_type: :group_label))

    @label = service.execute

    if @label.valid?
      redirect_to group_labels_path(@group)
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    service = Labels::UpdateService.new(@group, current_user, label_params)

    if service.execute(@label)
      redirect_to group_labels_path(@group)
    else
      render 'edit'
    end
  end

  def generate
    Labels::GenerateService.new(@group, current_user, label_type: :group_label).execute

    redirect_to group_labels_path(@group)
  end

  def destroy
    Labels::DestroyService.new(@group, current_user, label_type: :group_label).execute(@label)

    respond_to do |format|
      format.html do
        redirect_to group_labels_path(@group), notice: 'Label was removed'
      end
      format.js
    end
  end

  def toggle_subscription
    return unless current_user

    Labels::ToggleSubscriptionService.new(@group, current_user).execute(@label)

    head :ok
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

  def label_params
    params.require(:label).permit(:title, :description, :color)
  end
end
