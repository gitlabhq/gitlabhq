# frozen_string_literal: true

require 'chemlab/library'

# Chemlab Page Libraries for GitLab
module Gitlab
  include Chemlab::Library

  module Page
    module Main
      autoload :Login, 'gitlab/page/main/login'
      autoload :SignUp, 'gitlab/page/main/sign_up'
    end

    module Subscriptions
      autoload :New, 'gitlab/page/subscriptions/new'
    end

    module Admin
      autoload :Dashboard, 'gitlab/page/admin/dashboard'
      autoload :Subscription, 'gitlab/page/admin/subscription'
    end

    module Group
      module Settings
        autoload :Billing, 'gitlab/page/group/settings/billing'
        autoload :UsageQuotas, 'gitlab/page/group/settings/usage_quotas'
      end
    end
  end
end
