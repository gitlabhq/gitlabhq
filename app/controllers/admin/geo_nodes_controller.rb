class Admin::GeoNodesController < Admin::ApplicationController
  def index
    @nodes = GeoNode.all
    @node = GeoNode.new
    @node.build_geo_node_key
  end

  def create
    @node = GeoNode.new
    @node.build_geo_node_key
    @node.attributes = geo_node_params
    @node.geo_node_key.title = "Geo node: #{@node.url}"

    if @node.save
      redirect_to admin_geo_nodes_path, notice: 'Node was successfully created.'
    else
      @nodes = GeoNode.all
      render :index
    end
  end

  def destroy
    @node = GeoNode.find(params[:id])
    @node.destroy

    redirect_to admin_geo_nodes_path
  end

  def geo_node_params
    params.require(:geo_node).permit(:url, :primary, geo_node_key_attributes: [:key])
  end
end
