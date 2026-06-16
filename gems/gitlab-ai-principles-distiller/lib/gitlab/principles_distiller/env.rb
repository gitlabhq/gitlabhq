# frozen_string_literal: true

module Gitlab
  module PrinciplesDistiller
    # Env var names read by the gem. Constants here surface typos as
    # NameError rather than silent nil reads.
    module Env
      # Project-specific custom variables.
      CATALOG_PROJECT            = 'AGENT_PRINCIPLES_CATALOG_PROJECT'
      CATALOG_FLOW_NAME          = 'AGENT_PRINCIPLES_CATALOG_FLOW_NAME'
      CATALOG_ITEM_CONSUMER_ID   = 'AGENT_PRINCIPLES_CATALOG_ITEM_CONSUMER_ID'
      GITLAB_TOKEN               = 'GITLAB_TOKEN'
      GITLAB_API_TOKEN           = 'GITLAB_API_TOKEN'
      GITLAB_HOST                = 'GITLAB_HOST'

      # GitLab CI predefined variables.
      CI_PROJECT_DIR             = 'CI_PROJECT_DIR'
      CI_DEFAULT_BRANCH          = 'CI_DEFAULT_BRANCH'
      CI_COMMIT_REF_NAME         = 'CI_COMMIT_REF_NAME'
      CI_PROJECT_PATH            = 'CI_PROJECT_PATH'
      CI_PROJECT_ID              = 'CI_PROJECT_ID'
      CI_JOB_URL                 = 'CI_JOB_URL'
    end
  end
end
