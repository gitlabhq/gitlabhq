module Geo
  module Fdw
    class Project < ::Geo::BaseFdw
      self.table_name = Gitlab::Geo.fdw_table('projects')
    end
  end
end
