module Geo
  module Fdw
    class ProjectRepositoryState < ::Geo::BaseFdw
      self.table_name = Gitlab::Geo::Fdw.table('project_repository_states')
    end
  end
end
