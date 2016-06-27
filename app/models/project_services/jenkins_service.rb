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
class JenkinsService < CiService
  include HTTParty
  prop_accessor :jenkins_url, :project_name, :username, :password

  before_update :reset_password
  validates :username,
            presence: true,
            if: ->(service) { service.activated? && service.password.present? }

  default_value_for :push_events, true
  default_value_for :merge_requests_events, false
  default_value_for :tag_push_events, false

  after_save :compose_service_hook, if: :activated?

  def reset_password
    # don't reset the password if a new one is provided
    if jenkins_url_changed? && !password_touched?
      self.password = nil
    end
  end

  def compose_service_hook
    hook = service_hook || build_service_hook
    hook.url = hook_url
    hook.save
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])

    service_hook.execute(data, "#{data[:object_kind]}_hook")
  end

  def test(data)
    begin
      code, message = execute(data)
      return { success: false, result: message } if code != 200
    rescue StandardError => error
      return { success: false, result: error }
    end

    { success: true, result: message }
  end

  def auth
    require 'base64'
    Base64.urlsafe_encode64("#{username}:#{password}")
  end

  def hook_url
    File.join(jenkins_url, "project/#{project_name}").to_s
  end

  def supported_events
    %w(push merge_request tag_push)
  end

  def title
    'Jenkins CI'
  end

  def description
    'An extendable open source continuous integration server'
  end

  def help
    'You must have installed the Git Plugin and GitLab Plugin in Jenkins'
  end

  def to_param
    'jenkins'
  end

  def fields
    [
      {
        type: 'text', name: 'jenkins_url',
        placeholder: 'Jenkins URL like http://jenkins.example.com'
      },
      {
        type: 'text', name: 'project_name', placeholder: 'Project Name',
        help: 'The URL-friendly project name. Example: my_project_name'
      },
      { type: 'text', name: 'username' },
      { type: 'password', name: 'password' },
    ]
  end
end
