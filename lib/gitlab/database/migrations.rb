# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      REGULAR_PATH_REGEX = %r{db/(\w+/)?migrate}
      POST_DEPLOYMENT_PATH_REGEX = %r{db/(\w+/)?post_migrate}
    end
  end
end
