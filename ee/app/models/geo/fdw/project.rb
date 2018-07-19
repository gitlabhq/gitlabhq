module Geo
  module Fdw
    class Project < ::Geo::BaseFdw
      self.table_name = Gitlab::Geo::Fdw.table('projects')

      has_one :project_registry, class_name: 'Geo::ProjectRegistry'
    end
  end
end
