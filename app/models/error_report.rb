require "hoptoad_notifier"

##
# Processes a new error report.
#
# Accepts a hash with the following attributes:
#
# * <tt>:error_class</tt> - the class of error
# * <tt>:message</tt> - the error message
# * <tt>:backtrace</tt> - an array of stack trace lines
#
# * <tt>:request</tt> - a hash of values describing the request
# * <tt>:server_environment</tt> - a hash of values describing the server environment
#
# * <tt>:notifier</tt> - information to identify the source of the error report
#
class ErrorReport

  attr_reader :error_class, :message, :request, :server_environment, :api_key, :notifier, :user_attributes, :framework, :err

  def initialize(xml_or_attributes)
    @attributes = xml_or_attributes
    @attributes = Hoptoad.parse_xml!(@attributes) if @attributes.is_a? String
    @attributes = @attributes.with_indifferent_access
    @attributes.each { |k, v| instance_variable_set(:"@#{k}", v) }
  end

  def rails_env
    rails_env = server_environment['environment-name']
    rails_env = 'development' if rails_env.blank?
    rails_env
  end

  def project
    @project ||= Project.where(exceptions_token: api_key).first
  end

  def generate_err!
    return unless valid?
    return @err if @err
    @err = project.exceptions.create(
      message: message,
      error_class: error_class,
      request: request,
      server_environment: server_environment,
      notifier: notifier,
      user_attributes: user_attributes,
      framework: framework
    )
    @backtrace.each do |bt|
      err.err_backtraces.create(method: bt["method"], file: bt["file"], line: bt["number"])
    end
    @err

    @err.notify!
  end

  def valid?
    project.present?
  end

end
