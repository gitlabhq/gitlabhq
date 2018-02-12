module Geo
  module Fdw
    class ProjectFeature < ::Geo::BaseFdw
      self.table_name = Gitlab::Geo::Fdw.table('project_features')
    end
  end
end
