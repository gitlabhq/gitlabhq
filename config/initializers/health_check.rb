# HealthCheck.setup do |config|
#   # Text output upon success
#   config.success = 'success'
#
#   # Timeout in seconds used when checking smtp server
#   config.smtp_timeout = 30.0
#
#   # http status code used when plain text error message is output
#   # Set to 200 if you want your want to distinguish between partial (text does not include success) and
#   # total failure of rails application (http status of 500 etc)
#   config.http_status_for_error_text = 500
#
#   # http status code used when an error object is output (json or xml)
#   # Set to 200 if you want your want to distinguish between partial (healthy property == false) and
#   # total failure of rails application (http status of 500 etc)
#   config.http_status_for_error_object = 500
#
#   # You can customize which checks happen on a standard health check
#   config.standard_checks = [ 'database', 'migrations', 'custom' ]
#
#   # You can set what tests are run with the 'full' or 'all' parameter
#   config.full_checks = ['database', 'migrations', 'custom', 'email', 'cache']
#
#   # Add one or more custom checks that return a blank string if ok, or an error message if there is an error
#   config.add_custom_check do
#      any code that returns blank on success and non blank string upon failure
#   end
# end
