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
#

# Base class for CI services
# List methods you need to implement to get your CI service
# working with GitLab Merge Requests
class CiService < Service
  def category
    :ci
  end

  def supported_events
    %w(push)
  end

  # Return complete url to build page
  #
  # Ex.
  #   http://jenkins.example.com:8888/job/test1/scm/bySHA1/12d65c
  #
  def build_page(sha, ref)
    # implement inside child
  end

  # Return string with build status or :error symbol
  #
  # Allowed states: 'success', 'failed', 'running', 'pending', 'skipped'
  #
  #
  # Ex.
  #   @service.commit_status('13be4ac')
  #   # => 'success'
  #
  #   @service.commit_status('2abe4ac')
  #   # => 'running'
  #
  #
  def commit_status(sha, ref)
    # implement inside child
  end
end
