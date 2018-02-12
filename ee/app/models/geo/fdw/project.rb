module Geo
  module Fdw
    class Project < ::Geo::BaseFdw
      self.table_name = Gitlab::Geo::Fdw.table('projects')
    end
  end
end
