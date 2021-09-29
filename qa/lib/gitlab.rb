# frozen_string_literal: true

require 'chemlab/library'

# Chemlab Page Libraries for GitLab
module Gitlab
  include Chemlab::Library

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
        autoload :UsageQuotas, 'gitlab/page/group/settings/usage_quotas'
      end
    end
  end
end
