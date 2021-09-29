# frozen_string_literal: true

module Ci
  # TODO: https://gitlab.com/groups/gitlab-org/-/epics/6168
  #
  # Do not use this yet outside of `ci_instance_variables`.
  # This class is part of a migration to move all CI classes to a new separate database.
  # Initially we are only going to be moving the `Ci::InstanceVariable` model and it will be duplicated in the main and CI tables
  # Do not extend this class in any other models.
  class CiDatabaseRecord < Ci::ApplicationRecord
    self.abstract_class = true

    if Gitlab::Database.has_config?(:ci)
      connects_to database: { writing: :ci, reading: :ci }

      # TODO: Load Balancing messes with `CiDatabaseRecord`
      # returning wrong connection. To be removed once merged:
      # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/67773
      def self.connection
        retrieve_connection
      end
    end
  end
end
