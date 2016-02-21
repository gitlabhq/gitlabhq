class Admin::GeoNodesController < Admin::ApplicationController
  def index
    @nodes = GeoNode.all
    @node = GeoNode.new
  end

  def create
    @node = GeoNode.new(geo_node_params)

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
    params.require(:geo_node).permit(:url, :host, :port, :primary, :relative_url_root, :schema)
  end
end
