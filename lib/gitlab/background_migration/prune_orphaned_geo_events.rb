# frozen_string_literal: true
#
# rubocop:disable Style/Documentation

# This job is added to fix https://gitlab.com/gitlab-org/gitlab/issues/30229
# It's not used anywhere else.
# Can be removed in GitLab 13.*
module Gitlab
  module BackgroundMigration
    class PruneOrphanedGeoEvents
      def perform(table_name)
      end
    end
  end
end

Gitlab::BackgroundMigration::PruneOrphanedGeoEvents.prepend_if_ee('EE::Gitlab::BackgroundMigration::PruneOrphanedGeoEvents')
