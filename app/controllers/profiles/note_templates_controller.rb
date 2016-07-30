class Profiles::NoteTemplatesController < Profiles::ApplicationController
  before_action :authenticate_user!
  before_action :set_note_template, only: [:edit, :update, :destroy]

  def index
    @note_template = NoteTemplate.new
    @note_templates = current_user.note_templates

    respond_to do |format|
      format.html
      format.json do 
        render json: @note_templates, only: [:title, :note]
      end
    end
  end

  def edit
  end

  def create
    @note_template = NoteTemplate.new(note_template_params)
    @note_template.user = current_user

    if @note_template.save
      redirect_to(
        profile_note_templates_path,
        notice: "'#{@note_template.title}' was successfully created."
      )
    else
      render 'index'
    end
  end

  def update
    if @note_template.update_attributes(note_template_params)
      redirect_to(
        profile_note_templates_path,
        notice: "'#{@note_template.title}' was successfully updated."
      )
    else
      flash[:alert] = 'Failed to save note template.'
    end
  end

  def destroy
    if @note_template.destroy
      redirect_to(profile_note_templates_path, notice: "Note template was successfully deleted.")
    end
  end

  private

  def note_template_params
    params.require(:note_template).permit(:note, :title)
  end

  def set_note_template
    @note_template = current_user.note_templates.find(params["id"])
  end
end
