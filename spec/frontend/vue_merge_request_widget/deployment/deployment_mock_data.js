import {
  DEPLOYING,
  REDEPLOYING,
  SUCCESS,
  STOPPING,
} from '~/vue_merge_request_widget/components/deployment/constants';

const actionButtonMocks = {
  [STOPPING]: {
    actionName: STOPPING,
    buttonText: 'Stop environment',
    buttonVariant: 'danger',
    busyText: 'This environment is being deployed',
    confirmMessage: 'Are you sure you want to stop this environment?',
    errorMessage: 'Something went wrong while stopping this environment. Please try again.',
  },
  [DEPLOYING]: {
    actionName: DEPLOYING,
    buttonText: 'Deploy',
    buttonVariant: 'confirm',
    busyText: 'This environment is being deployed',
    confirmMessage: 'Are you sure you want to deploy this environment?',
    errorMessage: 'Something went wrong while deploying this environment. Please try again.',
  },
  [REDEPLOYING]: {
    actionName: REDEPLOYING,
    buttonText: 'Re-deploy',
    buttonVariant: 'confirm',
    busyText: 'This environment is being re-deployed',
    confirmMessage: 'Are you sure you want to re-deploy this environment?',
    errorMessage: 'Something went wrong while deploying this environment. Please try again.',
  },
};

const deploymentMockData = {
  id: 15,
  name: 'review/diplo',
  url: '/root/review-apps/environments/15',
  stop_url: '/root/review-apps/environments/15/stop',
  metrics_url: '/root/review-apps/environments/15/deployments/1/metrics',
  metrics_monitoring_url: '/root/review-apps/environments/15/metrics',
  external_url: 'http://gitlab.com.',
  external_url_formatted: 'gitlab',
  deployed_at: '2017-03-22T22:44:42.258Z',
  deployed_at_formatted: 'Mar 22, 2017 10:44pm',
  environment_available: true,
  details: {},
  status: SUCCESS,
  changes: [
    {
      path: 'index.html',
      external_url: 'http://root-main-patch-91341.volatile-watch.surge.sh/index.html',
    },
    {
      path: 'imgs/gallery.html',
      external_url: 'http://root-main-patch-91341.volatile-watch.surge.sh/imgs/gallery.html',
    },
    {
      path: 'about/',
      external_url: 'http://root-main-patch-91341.volatile-watch.surge.sh/about/',
    },
  ],
};

const playDetails = {
  playable_build: {
    play_path: '/root/test-deployments/-/jobs/1131/play',
  },
};

const retryDetails = {
  playable_build: {
    retry_path: '/root/test-deployments/-/jobs/1131/retry',
  },
};

const mockRedeployProps = {
  retry_url: retryDetails.playable_build.retry_path,
  environment_available: false,
};

export { actionButtonMocks, deploymentMockData, playDetails, retryDetails, mockRedeployProps };
