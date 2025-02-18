import { __, s__ } from '~/locale';
import { getDateInPast } from '~/lib/utils/datetime_utility';
import { helpPagePath } from '~/helpers/help_page_helper';
import { STATUS_READY, STATUS_PENDING, STATUS_FAILED } from '~/kubernetes_dashboard/constants';

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
  ACTIVE: 'active',
  STOPPED: 'stopped',
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

export const CLUSTER_STATUS_HEALTHY_TEXT = s__('Environment|Healthy');
export const CLUSTER_STATUS_UNHEALTHY_TEXT = s__('Environment|Unhealthy');

export const CLUSTER_HEALTH_SUCCESS = 'success';
export const CLUSTER_HEALTH_ERROR = 'error';

export const HEALTH_BADGES = {
  [CLUSTER_HEALTH_SUCCESS]: {
    variant: 'success',
    text: CLUSTER_STATUS_HEALTHY_TEXT,
    icon: 'status-success',
  },
  [CLUSTER_HEALTH_ERROR]: {
    variant: 'danger',
    text: CLUSTER_STATUS_UNHEALTHY_TEXT,
    icon: 'status-alert',
  },
};

export const SYNC_STATUS_BADGES = {
  reconciled: {
    variant: 'success',
    icon: 'status-success',
    text: s__('Environment|Reconciled'),
    popoverText: s__('Deployment|Flux sync reconciled successfully'),
  },
  reconciling: {
    variant: 'info',
    icon: 'status-running',
    text: s__('Environment|Reconciling'),
    popoverText: s__('Deployment|Flux sync reconciling'),
  },
  suspended: {
    variant: 'warning',
    icon: 'status-paused',
    text: __('Paused'),
    popoverText: s__('Deployment|Flux sync is suspended'),
  },
  stalled: {
    variant: 'warning',
    icon: 'status-paused',
    text: s__('Environment|Stalled'),
    popoverTitle: s__('Deployment|Flux sync stalled'),
  },
  failed: {
    variant: 'danger',
    icon: 'status-failed',
    text: s__('Deployment|Failed'),
    popoverTitle: s__('Deployment|Flux sync failed'),
  },
  unknown: {
    variant: 'neutral',
    icon: 'status-waiting',
    text: s__('Deployment|Unknown'),
    popoverTitle: s__('Deployment|Flux sync status is unknown'),
    popoverText: s__(
      'Deployment|Unable to detect state. %{linkStart}How are states detected?%{linkEnd}',
    ),
    popoverLink: 'https://gitlab.com/gitlab-org/gitlab/-/issues/419666#results',
  },
  unavailable: {
    variant: 'muted',
    icon: 'status-waiting',
    text: s__('Deployment|Unavailable'),
    popoverTitle: s__('Deployment|Flux sync status is unavailable'),
    popoverText: s__(
      'Deployment|Sync status is unknown. %{linkStart}How do I configure Flux for my deployment?%{linkEnd}',
    ),
    popoverLink: helpPagePath('user/clusters/agent/gitops/flux_tutorial'),
  },
};

export const STATUS_TRUE = 'True';
export const STATUS_FALSE = 'False';
export const STATUS_UNKNOWN = 'Unknown';

export const REASON_PROGRESSING = 'Progressing';

const ERROR_UNAUTHORIZED = 'unauthorized';
const ERROR_FORBIDDEN = 'forbidden';
const ERROR_NOT_FOUND = 'not found';
const ERROR_OTHER = 'other';

export const CLUSTER_AGENT_ERROR_MESSAGES = {
  [ERROR_UNAUTHORIZED]: s__(
    "Environment|You don't have permission to view all the namespaces in the cluster. If a namespace is not shown, you can still enter its name to select it.",
  ),
  [ERROR_FORBIDDEN]: s__(
    'Environment|Forbidden to access the cluster agent from this environment.',
  ),
  [ERROR_NOT_FOUND]: s__('Environment|Cluster agent not found.'),
  [ERROR_OTHER]: s__('Environment|There was an error connecting to the cluster agent.'),
};

export const CLUSTER_FLUX_RECOURSES_ERROR_MESSAGES = {
  [ERROR_UNAUTHORIZED]: s__(
    'Environment|Unauthorized to access %{resourceType} from this environment.',
  ),
  [ERROR_OTHER]: s__('Environment|There was an error fetching %{resourceType}.'),
};

export const HELM_RELEASES_RESOURCE_TYPE = 'helmreleases';
export const KUSTOMIZATIONS_RESOURCE_TYPE = 'kustomizations';

export const KUSTOMIZATION = 'Kustomization';
export const HELM_RELEASE = 'HelmRelease';
export const DEPLOYMENT_KIND = 'Deployment';

export const TREE_ITEM_KIND_ICONS = {
  [KUSTOMIZATION]: 'overview',
  [DEPLOYMENT_KIND]: 'deployments',
};

const RUNNING_STATUS_ICON = { icon: 'status-running', variant: 'info' };
const SUCCESS_STATUS_ICON = { icon: 'status-success', variant: 'success' };
const WAITING_STATUS_ICON = { icon: 'status-waiting', variant: 'subtle' };
const FAILED_STATUS_ICON = { icon: 'status-failed', variant: 'danger' };
const PAUSED_STATUS_ICON = { icon: 'status-paused', variant: 'warning' };

export const TREE_ITEM_STATUS_ICONS = {
  reconciled: SUCCESS_STATUS_ICON,
  reconciling: RUNNING_STATUS_ICON,
  reconcilingWithBadConfig: RUNNING_STATUS_ICON,
  stalled: PAUSED_STATUS_ICON,
  failed: FAILED_STATUS_ICON,
  unknown: WAITING_STATUS_ICON,
  unavailable: WAITING_STATUS_ICON,
  [STATUS_PENDING]: PAUSED_STATUS_ICON,
  [STATUS_READY]: SUCCESS_STATUS_ICON,
  [STATUS_FAILED]: FAILED_STATUS_ICON,
};

export const DELETE_POD_ACTION = {
  name: 'delete-pod',
  text: s__('KubernetesDashboard|Delete pod'),
  icon: 'remove',
  variant: 'danger',
  class: '!gl-text-red-500',
};

export const FLUX_RECONCILE_ACTION = {
  name: 'flux-reconcile',
  text: s__('KubernetesDashboard|Trigger reconciliation'),
  icon: 'retry',
};

export const FLUX_SUSPEND_ACTION = {
  name: 'flux-suspend',
  text: s__('KubernetesDashboard|Suspend reconciliation'),
  variant: 'danger',
  icon: 'stop',
};

export const FLUX_RESUME_ACTION = {
  name: 'flux-resume',
  text: s__('KubernetesDashboard|Resume reconciliation'),
  icon: 'play',
};
