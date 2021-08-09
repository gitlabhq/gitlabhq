# frozen_string_literal: true

# Chemlab Page Libraries for GitLab
module Gitlab
  module Page
    module Main
      autoload :Login, 'gitlab/page/main/login'
    end

    module Subscriptions
      autoload :New, 'gitlab/page/subscriptions/new'
    end

    module Group
      module Settings
        autoload :Billing, 'gitlab/page/group/settings/billing'
      end
    end
  end
end
