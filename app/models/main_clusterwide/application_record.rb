# frozen_string_literal: true

module MainClusterwide
  class ApplicationRecord < ::ApplicationRecord
    self.abstract_class = true

    if Gitlab::Database.has_config?(:main_clusterwide)
      connects_to database: { writing: :main_clusterwide, reading: :main_clusterwide }
    end
  end
end
