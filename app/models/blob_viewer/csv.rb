require 'csv'

module BlobViewer
  class CSV < Base
    include ServerSide

    self.binary = false
    self.extensions = %w(csv)
    self.partial_name = 'csv'
    self.switcher_icon = 'file-excel-o'
    self.type = :rich

    def parse(&block)
      begin
        ::CSV.parse(blob.data).each_with_index(&block)
      rescue ::CSV::MalformedCSVError => ex
        # TODO (rspeicher): How do we want to handle this?
      end
    end
  end
end
