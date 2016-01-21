class Admin::IpBlocking::IpBaseController < Admin::IpBlocking::BaseController

  private

  def search_in_collection
    @collection.where(ip: params[:search])
  end

  def row_attributes
    params.require(form_namespace).permit(
      :ip,
      :description
    )
  end

  def row_type_name
    'IP address'
  end
end
