# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Gitlab::Application.initialize!

require File.join(Rails.root, "lib", "gitlabhq", "git_host")
