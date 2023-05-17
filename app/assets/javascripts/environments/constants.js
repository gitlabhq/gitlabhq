import { __, s__ } from '~/locale';
import { getDateInPast } from '~/lib/utils/datetime_utility';

// These statuses are based on how the backend defines pod phases here
// lib/gitlab/kubernetes/pod.rb

export const STATUS_MAP = {
  succeeded: {
    class: 'succeeded',
    text: __('Succeeded'),
    stable: true,
  },
  running: {
    class: 'running',
    text: __('Running'),
    stable: true,
  },
  failed: {
    class: 'failed',
    text: __('Failed'),
    stable: true,
  },
  pending: {
    class: 'pending',
    text: __('Pending'),
    stable: true,
  },
  unknown: {
    class: 'unknown',
    text: __('Unknown'),
    stable: true,
  },
};

export const CANARY_STATUS = {
  class: 'canary-icon',
  text: __('Canary'),
  stable: false,
};

export const CANARY_UPDATE_MODAL = 'confirm-canary-change';

export const ENVIRONMENTS_SCOPE = {
  AVAILABLE: 'available',
  STOPPED: 'stopped',
};

export const ENVIRONMENT_COUNT_BY_SCOPE = {
  [ENVIRONMENTS_SCOPE.AVAILABLE]: 'availableCount',
  [ENVIRONMENTS_SCOPE.STOPPED]: 'stoppedCount',
};

export const REVIEW_APP_MODAL_I18N = {
  title: s__('Environments|Enable Review Apps'),
  intro: s__(
    'EnableReviewApp|Review apps are dynamic environments that you can use to provide a live preview of changes made in a feature branch.',
  ),
  instructions: {
    title: s__('EnableReviewApp|To configure a dynamic review app, you must:'),
    step1: s__(
      'EnableReviewApp|Have access to infrastructure that can host and deploy the review apps.',
    ),
    step2: s__('EnableReviewApp|Install and configure a runner to do the deployment.'),
    step3: s__('EnableReviewApp|Add a job in your CI/CD configuration that:'),
    step3a: s__('EnableReviewApp|Only runs for feature branches or merge requests.'),
    step3b: s__(
      'EnableReviewApp|Uses a predefined CI/CD variable like %{codeStart}$(CI_COMMIT_REF_SLUG)%{codeEnd} to dynamically create the review app environments. For example, for a configuration using merge request pipelines:',
    ),
    step4: s__('EnableReviewApp|Recommended: Set up a job that manually stops the Review Apps.'),
  },
  staticSitePopover: {
    title: s__('EnableReviewApp|Using a static site?'),
    body: s__(
      'EnableReviewApp|Make sure your project has an environment configured with the target URL set to your website URL. If not, create a new one before continuing.',
    ),
  },
  learnMore: __('Learn more'),
  viewMoreExampleProjects: s__('EnableReviewApp|View more example projects'),
  copyToClipboardText: s__('EnableReviewApp|Copy snippet'),
};

export const MIN_STALE_ENVIRONMENT_DATE = getDateInPast(new Date(), 3650); // 10 years ago
export const MAX_STALE_ENVIRONMENT_DATE = getDateInPast(new Date(), 7); // one week ago

export const ENVIRONMENT_NEW_HELP_TEXT = __(
  'Environments allow you to track deployments of your application.%{linkStart} More information.%{linkEnd}',
);

export const ENVIRONMENT_EDIT_HELP_TEXT = ENVIRONMENT_NEW_HELP_TEXT;

export const SERVICES_LIMIT_PER_PAGE = 10;
