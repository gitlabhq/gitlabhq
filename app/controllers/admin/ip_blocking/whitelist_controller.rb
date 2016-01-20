class Admin::IpBlocking::WhitelistController < Admin::ApplicationController
  before_action :set_ip, only: [:index]
  before_action :get_ip, only: [:edit, :update, :destroy]

  def index
    @ips = WhitelistedIp.all.order('id DESC')
    if params[:search].present?
      @ips = @ips.where(ip: params[:search])
    end

    @ips = @ips.page(params[:page]).per(30)
  end

  def create
    attrs = ip_attributes
    attrs[:user] = current_user

    @ip = WhitelistedIp.new(attrs)
    if @ip.save
      redirect_to admin_ip_blocking_whitelist_index_path,
                  notice: 'Added new IP address to the whitelist'
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @ip.update_attributes(ip_attributes)
      redirect_to admin_ip_blocking_whitelist_index_path,
                  notice: 'Updated IP address'
    else
      render 'edit'
    end
  end

  def destroy
    @ip.destroy
    redirect_to admin_ip_blocking_whitelist_index_path,
                notice: 'Removed IP address from the whitelist'
  end

  private

  def ip_attributes
    params.require(:whitelisted_ip).permit(
      :ip,
      :description
    )
  end

  def set_ip
    @ip = WhitelistedIp.new
  end

  def get_ip
    @ip = WhitelistedIp.find(params[:id])
  end
end
