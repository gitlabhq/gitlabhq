module Geo
  module Fdw
    class LfsObject < ::Geo::BaseFdw
      self.table_name = Gitlab::Geo.fdw_table('lfs_objects')
    end
  end
end

