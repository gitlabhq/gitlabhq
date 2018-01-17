class Admin::GeoNodesController < Admin::ApplicationController
  before_action :check_license, except: [:index, :destroy]
  before_action :load_node, only: [:edit, :update, :destroy, :repair, :toggle, :status]

  helper EE::GeoHelper

  def index
    @nodes = GeoNode.all.order(:id)
    @node = GeoNode.new

    unless Gitlab::Geo.license_allows?
      flash_now(:alert, 'You need a different license to enable Geo replication')
    end
  end

  def create
    @node = Geo::NodeCreateService.new(geo_node_params).execute

    if @node.persisted?
      redirect_to admin_geo_nodes_path, notice: 'Node was successfully created.'
    else
      @nodes = GeoNode.all

      render :new
    end
  end

  def new
    @node = GeoNode.new
  end

  def update
    if Geo::NodeUpdateService.new(@node, geo_node_params).execute
      redirect_to admin_geo_nodes_path, notice: 'Node was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @node.destroy

    redirect_to admin_geo_nodes_path, status: 302, notice: 'Node was successfully removed.'
  end

  def repair
    if !@node.missing_oauth_application?
      flash[:notice] = "This node doesn't need to be repaired."
    elsif @node.repair
      flash[:notice] = 'Node Authentication was successfully repaired.'
    else
      flash[:alert] = 'There was a problem repairing Node Authentication.'
    end

    redirect_to admin_geo_nodes_path
  end

  def toggle
    if @node.primary?
      flash[:alert] = "Primary node can't be disabled."
    else
      if @node.toggle!(:enabled)
        new_status = @node.enabled? ? 'enabled' : 'disabled'
        flash[:notice] = "Node #{@node.url} was successfully #{new_status}."
      else
        action = @node.enabled? ? 'disabling' : 'enabling'
        flash[:alert] = "There was a problem #{action} node #{@node.url}."
      end
    end

    redirect_to admin_geo_nodes_path
  end

  def status
    status = Geo::NodeStatusFetchService.new.call(@node)

    respond_to do |format|
      format.json do
        render json: GeoNodeStatusSerializer.new.represent(status)
      end
    end
  end

  private

  def geo_node_params
    params.require(:geo_node).permit(
      :url,
      :primary,
      :namespace_ids,
      :repos_max_capacity,
      :files_max_capacity
    )
  end

  def check_license
    unless Gitlab::Geo.license_allows?
      flash[:alert] = 'You need a different license to enable Geo replication'
      redirect_to admin_license_path
    end
  end

  def load_node
    @node = GeoNode.find(params[:id])
  end

  def flash_now(type, message)
    flash.now[type] = flash.now[type].blank? ? message : "#{flash.now[type]}<BR>#{message}".html_safe
  end
end
