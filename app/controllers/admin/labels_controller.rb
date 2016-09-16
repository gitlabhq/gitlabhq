class Admin::LabelsController < Admin::ApplicationController
  before_action :label, only: [:edit, :update, :destroy, :toggle_subscription]

  def index
    @labels = Label.global_labels.page(params[:page])
  end

  def new
    @label = Label.new
  end

  def edit
  end

  def create
    service = Labels::CreateService.new(nil, current_user, label_params.merge(label_type: :global_label))

    @label = service.execute

    if @label.valid?
      redirect_to admin_labels_url, notice: 'Label was created.'
    else
      render :new
    end
  end

  def update
    service = Labels::UpdateService.new(nil, current_user, label_params)

    if service.execute(@label)
      redirect_to admin_labels_path, notice: 'Label was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    Labels::DestroyService.new(nil, current_user).execute(@label)

    @labels = Label.global_labels

    respond_to do |format|
      format.html do
        redirect_to admin_labels_path, notice: 'Label was removed.'
      end
      format.js
    end
  end

  def toggle_subscription
    return unless current_user

    Labels::ToggleSubscriptionService.new(nil, current_user).execute(@label)

    head :ok
  end

  private

  def label
    @label = Label.with_type(:global_label).find(params[:id])
  end

  def label_params
    params[:label].permit(:title, :description, :color)
  end
end
