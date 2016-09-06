class Groups::LabelsController < Groups::ApplicationController
  include ToggleSubscriptionAction

  before_action :label, only: [:edit, :update, :destroy]
  before_action :authorize_admin_labels!, only: [:new, :create, :edit, :update, :generate, :destroy]

  respond_to :html

  def index
    @labels = @group.labels.unprioritized.page(params[:page])
  end

  def new
    @label = @group.labels.new
  end

  def create
    @label = @group.labels.create(label_params)

    if @label.valid?
      redirect_to group_labels_path(@group)
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @label.update_attributes(label_params)
      redirect_to group_labels_path(@group)
    else
      render 'edit'
    end
  end

  def generate
    redirect_to group_labels_path(@group)
  end

  def destroy
    @label.destroy

    respond_to do |format|
      format.html do
        redirect_to group_labels_path(@group), notice: 'Label was removed'
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

  def label_params
    params.require(:label).permit(:title, :description, :color)
  end
end
