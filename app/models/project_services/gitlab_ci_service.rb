# TODO(ayufan): The GitLabCiService is deprecated and the type should be removed when the database entries are removed
class GitlabCiService < CiService
  # We override the active accessor to always make GitLabCiService disabled
  # Otherwise the GitLabCiService can be picked, but should never be since it's deprecated
  def active
    false
  end
end
