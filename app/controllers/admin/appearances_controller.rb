class Admin::AppearancesController < Admin::ApplicationController
  before_filter :set_appearance, except: :create

  def show
  end

  def preview
  end

  def create
    @appearance = Appearance.new(appearance_params)

    if @appearance.save
      redirect_to admin_appearances_path, notice: 'Appearance was successfully created.'
    else
      render action: 'show'
    end
  end

  def update
    if @appearance.update(appearance_params)
      redirect_to admin_appearances_path, notice: 'Appearance was successfully updated.'
    else
      render action: 'show'
    end
  end

  def logo
    appearance = Appearance.last
    appearance.remove_logo!

    appearance.save

    redirect_to admin_appearances_path, notice: 'Logo was succesfully removed.'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_appearance
    @appearance = Appearance.last || Appearance.new
  end

  # Only allow a trusted parameter "white list" through.
  def appearance_params
    params.require(:appearance).permit(:title, :description, :logo, :updated_by)
  end
end
