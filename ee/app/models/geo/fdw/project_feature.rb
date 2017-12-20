module Geo
  module Fdw
    class ProjectFeature < ::Geo::BaseFdw
      self.table_name = Gitlab::Geo.fdw_table('project_features')
    end
  end
end
