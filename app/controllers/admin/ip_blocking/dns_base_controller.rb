class Admin::IpBlocking::DnsBaseController < Admin::IpBlocking::BaseController

  private

  def search_in_collection
    @collection.where(domain: params[:search])
  end

  def row_attributes
    params.require(form_namespace).permit(
      :domain,
      :weight
    )
  end

  def row_type_name
    'DNS list'
  end
end
