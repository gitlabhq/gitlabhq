# WARNING changes in this file must be manually propagated to gitaly-ruby.
#
# https://gitlab.com/gitlab-org/gitaly/blob/master/ruby/lib/gitlab/gollum.rb

module Gollum
  GIT_ADAPTER = "rugged".freeze
end
require "gollum-lib"

module Gollum
  class Page
    def text_data(encoding = nil)
      data = if raw_data.respond_to?(:encoding)
               raw_data.force_encoding(encoding || Encoding::UTF_8)
             else
               raw_data
             end

      Gitlab::EncodingHelper.encode!(data)
    end
  end
end

Rails.application.configure do
  config.after_initialize do
    Gollum::Page.per_page = Kaminari.config.default_per_page
  end
end
