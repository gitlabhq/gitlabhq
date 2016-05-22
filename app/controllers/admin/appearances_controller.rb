class Admin::AppearancesController < Admin::ApplicationController
  before_action :set_appearance, except: :create

  def show
  end

  def preview
  end

  def create
    @appearance = Appearance.new(appearance_params)

    if @appearance.save
      redirect_to admin_appearances_path, notice: '创建外观成功。'
    else
      render action: 'show'
    end
  end

  def update
    if @appearance.update(appearance_params)
      redirect_to admin_appearances_path, notice: '更新外观成功。'
    else
      render action: 'show'
    end
  end

  def logo
    @appearance.remove_logo!

    @appearance.save

    redirect_to admin_appearances_path, notice: 'Logo 删除成功。'
  end

  def header_logos
    @appearance.remove_header_logo!
    @appearance.save

    redirect_to admin_appearances_path, notice: '头部 Logo 删除成功。'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_appearance
    @appearance = Appearance.last || Appearance.new
  end

  # Only allow a trusted parameter "white list" through.
  def appearance_params
    params.require(:appearance).permit(
      :title, :description, :logo, :logo_cache, :header_logo, :header_logo_cache,
      :updated_by
    )
  end
end
