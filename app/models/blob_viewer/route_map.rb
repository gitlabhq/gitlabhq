# frozen_string_literal: true

module BlobViewer
  class RouteMap < Base
    include ServerSide
    include Auxiliary

    self.partial_name = 'route_map'
    self.loading_partial_name = 'route_map_loading'
    self.file_types = %i[route_map]
    self.binary = false

    def validation_message
      return @validation_message if defined?(@validation_message)

      prepare!

      @validation_message =
        begin
          Gitlab::RouteMap.new(blob.data)

          nil
        rescue Gitlab::RouteMap::FormatError => e
          e.message
        end
    end

    def valid?
      validation_message.blank?
    end
  end
end
