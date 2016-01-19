class Admin::IpBlocking::DnsWhitelistsController < Admin::ApplicationController
  before_action :set_dns_list, only: [:index]
  before_action :get_dns_list, only: [:edit, :update, :destroy]

  def index
    @dns_lists = DnsIpWhitelist.all.order('id DESC')
    if params[:search] && params[:search].empty? == false
      @dns_lists = @dns_lists.where(domain: params[:search].to_s)
    end

    @dns_lists = @dns_lists.page(params[:page]).per(30)
  end

  def create
    attrs = dns_list_attributes
    attrs[:user] = current_user

    @dns_list = DnsIpWhitelist.create(attrs)

    if @dns_list.valid?
      redirect_to admin_ip_blocking_dns_whitelists_path,
                  notice: 'Added new DNS whitelist'
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    @dns_list.update_attributes(dns_list_attributes)
    if @dns_list.valid?
      redirect_to admin_ip_blocking_dns_whitelists_path,
                  notice: 'Updated DNS whitelist'
    else
      render 'edit'
    end
  end

  def destroy
    @dns_list.destroy
    redirect_to admin_ip_blocking_dns_whitelists_path,
                notice: 'Removed DNS whitelist'
  end

  private

  def dns_list_attributes
    params.require(:dns_ip_whitelist).permit(
      :domain,
      :weight
    )
  end

  def set_dns_list
    @dns_list = DnsIpWhitelist.new
  end

  def get_dns_list
    @dns_list = DnsIpWhitelist.find(params[:id].to_i)
  end
end
