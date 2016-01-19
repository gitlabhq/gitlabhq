class Admin::IpBlocking::BlacklistController < Admin::ApplicationController
  before_action :set_ip, only: [:index]
  before_action :get_ip, only: [:edit, :update, :destroy]

  def index
    @ips = BlacklistedIp.all.order('id DESC')
    if params[:search] && params[:search].empty? == false
      @ips = @ips.where(ip: params[:search].to_s)
    end

    @ips = @ips.page(params[:page]).per(30)
  end

  def create
    attrs = ip_attributes
    attrs[:user] = current_user

    @ip = BlacklistedIp.create(attrs)

    if @ip.valid?
      redirect_to admin_ip_blocking_blacklist_index_path,
                  notice: 'Added new IP address to the blacklist'
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    @ip.update_attributes(ip_attributes)
    if @ip.valid?
      redirect_to admin_ip_blocking_blacklist_index_path,
                  notice: 'Updated IP address'
    else
      render 'edit'
    end
  end

  def destroy
    @ip.destroy
    redirect_to admin_ip_blocking_blacklist_index_path,
                notice: 'Removed IP address from the blacklist'
  end

  private

  def ip_attributes
    params.require(:blacklisted_ip).permit(
      :ip,
      :description
    )
  end

  def set_ip
    @ip = BlacklistedIp.new
  end

  def get_ip
    @ip = BlacklistedIp.find(params[:id].to_i)
  end
end
