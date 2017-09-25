class Admin::LabelsController < Admin::ApplicationController
  before_action :set_label, only: [:show, :edit, :update, :destroy]

  def index
    @labels = Label.templates.page(params[:page])
  end

  def show
  end

  def new
    @label = Label.new
  end

  def edit
  end

  def create
    @label = Labels::CreateService.new(label_params).execute(template: true)

    if @label.persisted?
      redirect_to admin_labels_url, notice: "Label was created"
    else
      render :new
    end
  end

  def update
    @label = Labels::UpdateService.new(label_params).execute(@label)

    if @label.valid?
      redirect_to admin_labels_path, notice: 'Label was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @label.destroy
    @labels = Label.templates

    respond_to do |format|
      format.html do
        redirect_to admin_labels_path, status: 302, notice: 'Label was removed'
      end
      format.js
    end
  end

  private

  def set_label
    @label = Label.find(params[:id])
  end

  def label_params
    params[:label].permit(:title, :description, :color)
  end
end
