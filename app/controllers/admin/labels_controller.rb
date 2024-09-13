# frozen_string_literal: true

class Admin::LabelsController < Admin::ApplicationController
  before_action :set_label, only: [:show, :edit, :update, :destroy]

  feature_category :team_planning
  urgency :low

  def index
    @labels = Label.templates.page(pagination_params[:page])
  end

  def show; end

  def new
    @label = Label.new
  end

  def edit; end

  def create
    @label = Labels::CreateService.new(label_params).execute(template: true)

    if @label.persisted?
      redirect_to admin_labels_url, notice: _("Label was created")
    else
      render :new
    end
  end

  def update
    @label = Labels::UpdateService.new(label_params).execute(@label)

    if @label.valid?
      redirect_to admin_labels_path, notice: _('Label was successfully updated.')
    else
      render :edit
    end
  end

  def destroy
    respond_to do |format|
      if @label.destroy
        format.html do
          redirect_to admin_labels_path, status: :found,
            notice: format(_('%{label_name} was removed'), label_name: @label.name)
        end
        format.js { head :ok }
      else
        format.html do
          redirect_to admin_labels_path, status: :found,
            alert: @label.errors.full_messages.to_sentence
        end
        format.js { head :unprocessable_entity }
      end
    end
  end

  private

  def set_label
    @label = Label.find(params.permit(:id)[:id])
  end

  def label_params
    params[:label].permit(:title, :description, :color) # rubocop:disable Rails/StrongParams -- hash access is safely followed by permit
  end
end
