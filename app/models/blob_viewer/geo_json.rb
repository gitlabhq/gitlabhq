# frozen_string_literal: true

module BlobViewer
  class GeoJson < Base
    include Rich
    include ClientSide

    self.binary = false
    self.extensions = %w[geojson]
    self.partial_name = 'geo_json'
  end
end
