# frozen_string_literal: true

module Mutations
  module Ci
    # TODO: Remove in 16.0, see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87002
    class CiCdSettingsUpdate < ProjectCiCdSettingsUpdate
      graphql_name 'CiCdSettingsUpdate'
    end
  end
end
