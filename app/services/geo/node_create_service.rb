module Geo
  class NodeCreateService
    attr_reader :params

    def initialize(params)
      @params = params.dup
      @params[:namespace_ids] = @params[:namespace_ids].to_s.split(',')
    end

    def execute
      GeoNode.create(params).persisted?
    end
  end
end
