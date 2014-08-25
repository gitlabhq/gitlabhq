# == Schema Information
#
# Table name: services
#
#  id          :integer          not null, primary key
#  type        :string(255)
#  title       :string(255)
#  token       :string(255)
#  project_id  :integer          not null
#  created_at  :datetime
#  updated_at  :datetime
#  active      :boolean          default(FALSE), not null
#  project_url :string(255)
#  subdomain   :string(255)
#  room        :string(255)
#  recipients  :text
#  api_key     :string(255)
#

# Base class for CI services
# List methods you need to implement to get your CI service
# working with GitLab Merge Requests
class CiService < Service
  def category
    :ci
  end

  # Return complete url to build page
  #
  # Ex.
  #   http://jenkins.example.com:8888/job/test1/scm/bySHA1/12d65c
  #
  def build_page(sha)
    # implement inside child
  end

  # Return string with build status or :error symbol
  #
  # Allowed states: 'success', 'failed', 'running', 'pending'
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
  def commit_status(sha)
    # implement inside child
  end
end
