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

    redirect_to admin_geo_nodes_path, notice: 'Node was successfully removed.'
  end

  def repair
    @node = GeoNode.find(params[:id])

    if @node.primary? || !@node.missing_oauth_application?
      flash[:notice] = "This node doesn't need to be repaired."
    elsif @node.save
      flash[:notice] = 'Node Authentication was successfully repaired.'
    else
      flash[:alert] = 'There was a problem repairing Node Authentication.'
    end

    redirect_to admin_geo_nodes_path
  end

  private

  def geo_node_params
    params.require(:geo_node).permit(:url, :primary, geo_node_key_attributes: [:key])
  end
end
