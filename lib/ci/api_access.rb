module Ci
  module ApiAccess
    def build_artifact_upload_url(build_id, token)
      "#{Settings.gitlab_ci.url}/ci/api/v1/builds/#{build_id}/artifacts?token=#{token}"
    end
  end
end
