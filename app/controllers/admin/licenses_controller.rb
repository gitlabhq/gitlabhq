class Admin::LicensesController < Admin::ApplicationController
  before_action :license, only: [:show, :download, :destroy]
  before_action :require_license, only: [:show, :download, :destroy]

  respond_to :html

  def show
    @previous_licenses = License.all.to_a[0..-2].reverse
  end

  def download
    send_data @license.data, filename: @license.data_filename, disposition: 'attachment'
  end

  def new
    @license = License.new
  end

  def create
    @license = License.new
    @license.data_file = license_params[:data_file]

    respond_with(@license, location: admin_license_path) do
      if @license.save
        flash[:notice] = "The license was successfully uploaded."
      end
    end
  end

  def destroy
    license.destroy

    redirect_to admin_license_path, notice: "The license was removed."
  end

  private

  def license
    @license ||= begin
      License.reset_current
      License.current
    end
  end

  def require_license
    return if license

    redirect_to new_admin_license_path
  end

  def license_params
    params.require(:license).permit(:data_file)
  end
end
