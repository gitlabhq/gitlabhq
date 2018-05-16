# WARNING changes in this file must be manually propagated to gitaly-ruby.
#
# https://gitlab.com/gitlab-org/gitaly/blob/master/ruby/lib/gitlab/gollum.rb

module Gollum
  GIT_ADAPTER = "rugged".freeze
end
require "gollum-lib"

Rails.application.configure do
  config.after_initialize do
    Gollum::Page.per_page = Kaminari.config.default_per_page
  end
end
