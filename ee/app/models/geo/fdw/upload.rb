module Geo
  module Fdw
    class Upload < ::Geo::BaseFdw
      self.table_name = Gitlab::Geo.fdw_table('uploads')
    end
  end
end
