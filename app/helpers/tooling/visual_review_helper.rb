# frozen_string_literal: true

module Tooling
  module VisualReviewHelper
    # Since we only use the visual review toolbar for the gitlab project,
    # we can hardcode the project ID and project path for now.
    #
    # If we need to extend the review apps to other applications in the future,
    # we should create REVIEW_APPS_PROJECT_ID and REVIEW_APPS_PROJECT_PATH
    # environment variables (mapped to CI_PROJECT_ID and CI_PROJECT_PATH respectively),
    # as well as setting `data-require-auth` according to the project visibility.
    GITLAB_INSTANCE_URL            = 'https://gitlab.com'
    GITLAB_ORG_GITLAB_PROJECT_ID   = '278964'
    GITLAB_ORG_GITLAB_PROJECT_PATH = 'gitlab-org/gitlab'

    def visual_review_toolbar_options
      { 'data-merge-request-id': ENV['REVIEW_APPS_MERGE_REQUEST_IID'].to_s,
        'data-mr-url': GITLAB_INSTANCE_URL,
        'data-project-id': GITLAB_ORG_GITLAB_PROJECT_ID,
        'data-project-path': GITLAB_ORG_GITLAB_PROJECT_PATH,
        'data-require-auth': false,
        'id': 'review-app-toolbar-script',
        'src': 'https://gitlab.com/assets/webpack/visual_review_toolbar.js' }
    end

    def review_apps_enabled?
      Gitlab::Utils.to_boolean(ENV['REVIEW_APPS_ENABLED'], default: false)
    end
  end
end
