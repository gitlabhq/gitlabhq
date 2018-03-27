class JenkinsService < CiService
  prop_accessor :jenkins_url, :project_name, :username, :password

  before_update :reset_password

  validates :jenkins_url, presence: true, url: true, if: :activated?
  validates :project_name, presence: true, if: :activated?
  validates :username, presence: true, if: ->(service) { service.activated? && service.password_touched? }

  default_value_for :push_events, true
  default_value_for :merge_requests_events, false
  default_value_for :tag_push_events, false

  after_save :compose_service_hook, if: :activated?

  def reset_password
    # don't reset the password if a new one is provided
    if (jenkins_url_changed? || username.blank?) && !password_touched?
      self.password = nil
    end
  end

  def compose_service_hook
    hook = service_hook || build_service_hook
    hook.url = hook_url
    hook.save
  end

  def execute(data)
    return if project.disabled_services.include?(to_param)
    return unless supported_events.include?(data[:object_kind])

    service_hook.execute(data, "#{data[:object_kind]}_hook")
  end

  def test(data)
    begin
      result = execute(data)
      return { success: false, result: result[:message] } if result[:http_status] != 200
    rescue StandardError => error
      return { success: false, result: error }
    end

    { success: true, result: result[:message] }
  end

  def hook_url
    url = URI.parse(jenkins_url)
    url.path = File.join(url.path || '/', "project/#{project_name}")
    url.user = ERB::Util.url_encode(username) unless username.blank?
    url.password = ERB::Util.url_encode(password) unless password.blank?
    url.to_s
  end

  def self.supported_events
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

  def self.to_param
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
      { type: 'password', name: 'password' }
    ]
  end
end
