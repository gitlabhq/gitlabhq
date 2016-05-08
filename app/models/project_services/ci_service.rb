# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string
#  title                 :string
#  project_id            :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  active                :boolean          not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#  build_events          :boolean          default(FALSE), not null
#  category              :string           default("common"), not null
#  default               :boolean          default(FALSE)
#  wiki_page_events      :boolean          default(TRUE)
#

# Base class for CI services
# List methods you need to implement to get your CI service
# working with GitLab Merge Requests
class CiService < Service
  default_value_for :category, 'ci'

  def valid_token?(token)
    self.respond_to?(:token) && self.token.present? && ActiveSupport::SecurityUtils.variable_size_secure_compare(token, self.token)
  end

  def supported_events
    %w(push)
  end

  def merge_request_page(iid, sha, ref)
    commit_page(sha, ref)
  end

  def commit_page(sha, ref)
    build_page(sha, ref)
  end

  # Return complete url to merge_request page
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
  #   @service.merge_request_status(9, '13be4ac', 'dev')
  #   # => 'success'
  #
  #   @service.merge_request_status(10, '2abe4ac', 'dev)
  #   # => 'running'
  #
  #
  def merge_request_status(iid, sha, ref)
    commit_status(sha, ref)
  end

  # Return string with build status or :error symbol
  #
  # Allowed states: 'success', 'failed', 'running', 'pending', 'skipped'
  #
  #
  # Ex.
  #   @service.commit_status('13be4ac', 'master')
  #   # => 'success'
  #
  #   @service.commit_status('2abe4ac', 'dev')
  #   # => 'running'
  #
  #
  def commit_status(sha, ref)
    # implement inside child
  end
end
