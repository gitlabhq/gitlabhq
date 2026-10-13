const deployBoardMockData = {
  instances: [
    { status: 'finished', tooltip: 'tanuki-2334 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2335 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2336 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2337 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2338 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2339 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2340 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2334 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2335 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2336 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2337 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2338 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2339 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2340 Finished', pod_name: 'production-tanuki-1' },
    { status: 'deploying', tooltip: 'tanuki-2341 Deploying', pod_name: 'production-tanuki-1' },
    { status: 'deploying', tooltip: 'tanuki-2342 Deploying', pod_name: 'production-tanuki-1' },
    { status: 'deploying', tooltip: 'tanuki-2343 Deploying', pod_name: 'production-tanuki-1' },
    { status: 'failed', tooltip: 'tanuki-2344 Failed', pod_name: 'production-tanuki-1' },
    { status: 'ready', tooltip: 'tanuki-2345 Ready', pod_name: 'production-tanuki-1' },
    { status: 'ready', tooltip: 'tanuki-2346 Ready', pod_name: 'production-tanuki-1' },
    { status: 'preparing', tooltip: 'tanuki-2348 Preparing', pod_name: 'production-tanuki-1' },
    { status: 'preparing', tooltip: 'tanuki-2349 Preparing', pod_name: 'production-tanuki-1' },
    { status: 'preparing', tooltip: 'tanuki-2350 Preparing', pod_name: 'production-tanuki-1' },
    { status: 'preparing', tooltip: 'tanuki-2353 Preparing', pod_name: 'production-tanuki-1' },
    { status: 'waiting', tooltip: 'tanuki-2354 Waiting', pod_name: 'production-tanuki-1' },
    { status: 'waiting', tooltip: 'tanuki-2355 Waiting', pod_name: 'production-tanuki-1' },
    { status: 'waiting', tooltip: 'tanuki-2356 Waiting', pod_name: 'production-tanuki-1' },
  ],
  abortUrl: 'url',
  rollbackUrl: 'url',
  completion: 100,
  status: 'found',
  canaryIngress: {
    canaryWeight: 50,
  },
};

const createEnvironment = (data = {}) => ({
  id: 1,
  name: 'My environment',
  externalUrl: 'my external url',
  isAvailable: true,
  hasTerminals: false,
  autoStopAt: null,
  ...data,
});

const mockKasTunnelUrl = 'https://kas.gitlab.com/k8s-proxy';

const fluxResourceStatus = [{ status: 'True', type: 'Ready', message: '', reason: '' }];
const fluxKustomization = {
  kind: 'Kustomization',
  status: { conditions: fluxResourceStatus },
  spec: {},
  metadata: {
    name: 'my-kustomization',
    namespace: 'my-namespace',
    creationTimestamp: '',
    labels: {},
    annotations: {},
  },
  conditions: fluxResourceStatus,
  inventory: [
    { id: 'flux-system_notification-controller_apps_Deployment' },
    { id: 'flux-system_source-controller_apps_Deployment' },
  ],
  __typename: 'LocalWorkloadItem',
};

const k8sDeploymentsMock = [
  {
    metadata: { name: 'notification-controller' },
    status: {
      conditions: [
        { type: 'Available', status: 'True' },
        { type: 'Progressing', status: 'False' },
      ],
    },
  },
  {
    metadata: { name: 'source-controller' },
    status: {
      conditions: [
        { type: 'Available', status: 'False' },
        { type: 'Progressing', status: 'True' },
      ],
    },
  },
];

export {
  deployBoardMockData,
  createEnvironment,
  mockKasTunnelUrl,
  fluxResourceStatus,
  fluxKustomization,
  k8sDeploymentsMock,
};
