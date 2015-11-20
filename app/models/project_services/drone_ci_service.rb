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

class DroneCiService < CiService
  
  prop_accessor :drone_url, :token, :enable_ssl_verification
  validates :drone_url,
    presence: true,
    format: { with: /\A#{URI.regexp(%w(http https))}\z/, message: "should be a valid url" }, if: :activated?
  validates :token,
    presence: true,
    if: :activated?

  after_save :compose_service_hook, if: :activated?

  def compose_service_hook
    hook = service_hook || build_service_hook
    # If using a service template, project may not be available
    hook.url = [drone_url, "/api/hook", "?owner=#{project.namespace.path}", "&name=#{project.path}", "&access_token=#{token}"].join if project
    hook.enable_ssl_verification = enable_ssl_verification
    hook.save
  end

  def execute(data)
    case data[:object_kind]
    when 'push'
      service_hook.execute(data) if push_valid?(data)
    when 'merge_request'
      service_hook.execute(data) if merge_request_valid?(data)
    when 'tag_push'
      service_hook.execute(data) if tag_push_valid?(data)
    end
  end

  def allow_target_ci?
    true
  end

  def supported_events
    %w(push merge_request tag_push)
  end

  def merge_request_status_path(iid, sha = nil, ref = nil)
    url = [drone_url, 
           "gitlab/#{project.namespace.path}/#{project.path}/pulls/#{iid}", 
           "?access_token=#{token}"]

    URI.join(*url).to_s
  end

  def commit_status_path(sha, ref)
    url = [drone_url, 
           "gitlab/#{project.namespace.path}/#{project.path}/commits/#{sha}", 
           "?branch=#{URI::encode(ref.to_s)}&access_token=#{token}"]

    URI.join(*url).to_s
  end

  def merge_request_status(iid, sha, ref)
    response = HTTParty.get(merge_request_status_path(iid), verify: enable_ssl_verification)

    if response.code == 200 and response['status']
      case response['status']
      when 'killed'
        :canceled
      when 'failure', 'error'
        # Because drone return error if some test env failed
        :failed
      else
        response["status"]
      end
    else
      :error
    end
  rescue Errno::ECONNREFUSED
    :error
  end

  def commit_status(sha, ref)
    response = HTTParty.get(commit_status_path(sha, ref), verify: enable_ssl_verification)

    if response.code == 200 and response['status']
      case response['status']
      when 'killed'
        :canceled
      when 'failure', 'error'
        # Because drone return error if some test env failed
        :failed
      else
        response["status"]
      end
    else
      :error
    end
  rescue Errno::ECONNREFUSED
    :error
  end

  def merge_request_page(iid, sha, ref)
    url = [drone_url, 
           "gitlab/#{project.namespace.path}/#{project.path}/redirect/pulls/#{iid}"]

    URI.join(*url).to_s
  end

  def commit_page(sha, ref)
    url = [drone_url, 
           "gitlab/#{project.namespace.path}/#{project.path}/redirect/commits/#{sha}", 
           "?branch=#{URI::encode(ref.to_s)}"]

    URI.join(*url).to_s
  end

  def commit_coverage(sha, ref)
    nil
  end

  def build_page(sha, ref)
    commit_page(sha, ref)
  end

  def title
    'Drone CI'
  end

  def description
    'Drone is a Continuous Integration platform built on Docker, written in Go'
  end

  def to_param
    'drone_ci'
  end

  def fields
    [
      { type: 'text', name: 'token', placeholder: 'Drone CI project specific token' },
      { type: 'text', name: 'drone_url', placeholder: 'http://drone.example.com' },
      { type: 'checkbox', name: 'enable_ssl_verification', title: "Enable SSL verification" }
    ]
  end

  private

  def tag_push_valid?(data)
    data[:total_commits_count] > 0 && !Gitlab::Git.blank_ref?(data[:after])
  end

  def push_valid?(data)
    opened_merge_requests = project.merge_requests.opened.where(source_project_id: project.id, 
                                                                source_branch: Gitlab::Git.ref_name(data[:ref]))

    opened_merge_requests.empty? && data[:total_commits_count] > 0 && 
      !Gitlab::Git.blank_ref?(data[:after])
  end

  def merge_request_valid?(data)
    ['opened', 'reopened'].include?(data[:object_attributes][:state]) &&
      data[:object_attributes][:merge_status] == 'unchecked'
  end
end
