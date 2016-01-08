# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#  build_events          :boolean          default(FALSE), not null
#

# TODO(ayufan): The GitLabCiService is deprecated and the type should be removed when the database entries are removed
class GitlabCiService < CiService
  # We override the active accessor to always make GitLabCiService disabled
  # Otherwise the GitLabCiService can be picked, but should never be since it's deprecated
  def active
    false
  end
end
