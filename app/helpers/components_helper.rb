# frozen_string_literal: true

module ComponentsHelper
  def gitlab_workhorse_version
    if request.headers['Gitlab-Workhorse'].present?
      request.headers['Gitlab-Workhorse'].split('-').first
    else
      Gitlab::Workhorse.version
    end
  end
end
