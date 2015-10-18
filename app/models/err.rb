class Err < ActiveRecord::Base

  serialize :server_environment
  serialize :request
  serialize :notifier
  serialize :user_attributes
  
  belongs_to :project
  has_many :err_backtraces

  default_value_for :resolved, false

  scope :resolved, lambda { where('resolved = ?', true) }
  scope :unresolved, lambda { where('resolved = ?', false) }

  def notify!
    # if ENV["SLACK_WEBHOOK_URL"].present?
    #   notifier = Slack::Notifier.new ENV["SLACK_WEBHOOK_URL"]

    #   message = "#{self.application.name} - [#{self.message}](#{locate_url(self.id, host: ENV["DOMAIN"])})"
    #   msg = Slack::Notifier::LinkFormatter.format(message)

    #   notifier.ping msg
    # end

    # only send an exception email if the last exception isn't the same
    if self.project.exceptions.unresolved.where(error_class: self.error_class).count > 1
      # the error is the same so do nothing
    else
      ExceptionsMailer.err(self.id).deliver_now
    end
  end

  def user_agent
    agent_string = env_vars['HTTP_USER_AGENT']
    agent_string.blank? ? nil : UserAgent.parse(agent_string)
  end

  def user_agent_string
    if user_agent.nil? || user_agent.none?
      "N/A"
    else
      "#{user_agent.browser} #{user_agent.version} (#{user_agent.os})"
    end
  end

  def environment_name
    server_environment['server-environment'] || server_environment['environment-name']
  end

  def component
    request['component']
  end

  def action
    request['action']
  end

  def where
    if request_component.present?
      request_component + "#" + request_action
    else
      where = component.to_s.dup
      where << "##{action}" if action.present?
      where
    end
  end

  def request
    super || {}
  end

  def url
    request_url || request['url']
  end

  def host
    uri = url && URI.parse(url)
    uri.blank? ? "N/A" : uri.host
  rescue URI::InvalidURIError
    "N/A"
  end

  def to_curl
    return "N/A" if url.blank?
    headers = %w(Accept Accept-Encoding Accept-Language Cookie Referer User-Agent).each_with_object([]) do |name, h|
      if value = env_vars["HTTP_#{name.underscore.upcase}"]
        h << "-H '#{name}: #{value}'"
      end
    end

    "curl -X #{env_vars['REQUEST_METHOD'] || 'GET'} #{headers.join(' ')} #{url}"
  end

  def env_vars
    request['cgi-data'] || {}
  end

  def params
    request['params'] || {}
  end

  def session
    request['session'] || {}
  end

  def in_app_backtrace_lines
    backtrace.backtrace_lines.in_app
  end

  def similar_count
    problem.notices_count
  end

  def emailable?
    app.email_at_notices.include?(similar_count)
  end

  def should_email?
    app.emailable? && emailable?
  end

  def should_notify?
    true
  end

  ##
  # TODO: Move on decorator maybe
  #
  def project_root
    if server_environment
      server_environment['project-root'] || ''
    end
  end

  def app_version
    if server_environment
      server_environment['app-version'] || ''
    end
  end

end
