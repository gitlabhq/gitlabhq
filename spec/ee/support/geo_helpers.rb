module EE
  module GeoHelpers
    def stub_current_geo_node(node)
      allow(::Gitlab::Geo).to receive(:current_node).and_return(node)
    end
  end
end
