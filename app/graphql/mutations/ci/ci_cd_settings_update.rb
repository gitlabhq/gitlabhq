# frozen_string_literal: true

module Mutations
  module Ci
    # TODO: Remove after 16.0, see https://gitlab.com/gitlab-org/gitlab/-/issues/361801#note_1373963840
    class CiCdSettingsUpdate < ProjectCiCdSettingsUpdate
      graphql_name 'CiCdSettingsUpdate'

      def ready?(**args)
        raise Gitlab::Graphql::Errors::ResourceNotAvailable, '`remove_cicd_settings_update` feature flag is enabled.' \
          if Feature.enabled?(:remove_cicd_settings_update)

        super
      end
    end
  end
end
