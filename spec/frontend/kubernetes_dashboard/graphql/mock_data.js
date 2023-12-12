const runningPod = {
  status: { phase: 'Running' },
  metadata: {
    name: 'pod-1',
    namespace: 'default',
    creationTimestamp: '2023-07-31T11:50:17Z',
    labels: { key: 'value' },
    annotations: { annotation: 'text', another: 'text' },
  },
};
const pendingPod = {
  status: { phase: 'Pending' },
  metadata: {
    name: 'pod-2',
    namespace: 'new-namespace',
    creationTimestamp: '2023-11-21T11:50:59Z',
    labels: {},
    annotations: {},
  },
};
const succeededPod = {
  status: { phase: 'Succeeded' },
  metadata: {
    name: 'pod-3',
    namespace: 'default',
    creationTimestamp: '2023-07-31T11:50:17Z',
    labels: {},
    annotations: {},
  },
};
const failedPod = {
  status: { phase: 'Failed' },
  metadata: {
    name: 'pod-4',
    namespace: 'default',
    creationTimestamp: '2023-11-21T11:50:59Z',
    labels: {},
    annotations: {},
  },
};

export const k8sPodsMock = [runningPod, runningPod, pendingPod, succeededPod, failedPod, failedPod];

export const mockPodStats = [
  {
    title: 'Running',
    value: 2,
  },
  {
    title: 'Pending',
    value: 1,
  },
  {
    title: 'Succeeded',
    value: 1,
  },
  {
    title: 'Failed',
    value: 2,
  },
];

export const mockPodsTableItems = [
  {
    name: 'pod-1',
    namespace: 'default',
    status: 'Running',
    age: '114d',
    labels: { key: 'value' },
    annotations: { annotation: 'text', another: 'text' },
    kind: 'Pod',
  },
  {
    name: 'pod-1',
    namespace: 'default',
    status: 'Running',
    age: '114d',
    labels: {},
    annotations: {},
    kind: 'Pod',
  },
  {
    name: 'pod-2',
    namespace: 'new-namespace',
    status: 'Pending',
    age: '1d',
    labels: {},
    annotations: {},
    kind: 'Pod',
  },
  {
    name: 'pod-3',
    namespace: 'default',
    status: 'Succeeded',
    age: '114d',
    labels: {},
    annotations: {},
    kind: 'Pod',
  },
  {
    name: 'pod-4',
    namespace: 'default',
    status: 'Failed',
    age: '1d',
    labels: {},
    annotations: {},
    kind: 'Pod',
  },
  {
    name: 'pod-4',
    namespace: 'default',
    status: 'Failed',
    age: '1d',
    labels: {},
    annotations: {},
    kind: 'Pod',
  },
];

const pendingDeployment = {
  status: {
    conditions: [
      { type: 'Available', status: 'False' },
      { type: 'Progressing', status: 'True' },
    ],
  },
  metadata: {
    name: 'deployment-1',
    namespace: 'new-namespace',
    creationTimestamp: '2023-11-21T11:50:59Z',
    labels: {},
    annotations: {},
  },
};
const readyDeployment = {
  status: {
    conditions: [
      { type: 'Available', status: 'True' },
      { type: 'Progressing', status: 'False' },
    ],
  },
  metadata: {
    name: 'deployment-2',
    namespace: 'default',
    creationTimestamp: '2023-07-31T11:50:17Z',
    labels: {},
    annotations: {},
  },
};
const failedDeployment = {
  status: {
    conditions: [
      { type: 'Available', status: 'False' },
      { type: 'Progressing', status: 'False' },
    ],
  },
  metadata: {
    name: 'deployment-3',
    namespace: 'default',
    creationTimestamp: '2023-11-21T11:50:59Z',
    labels: {},
    annotations: {},
  },
};

export const k8sDeploymentsMock = [
  pendingDeployment,
  readyDeployment,
  readyDeployment,
  failedDeployment,
];

export const mockDeploymentsStats = [
  {
    title: 'Ready',
    value: 2,
  },
  {
    title: 'Failed',
    value: 1,
  },
  {
    title: 'Pending',
    value: 1,
  },
];

export const mockDeploymentsTableItems = [
  {
    name: 'deployment-1',
    namespace: 'new-namespace',
    status: 'Pending',
    age: '1d',
    labels: {},
    annotations: {},
    kind: 'Deployment',
  },
  {
    name: 'deployment-2',
    namespace: 'default',
    status: 'Ready',
    age: '114d',
    labels: {},
    annotations: {},
    kind: 'Deployment',
  },
  {
    name: 'deployment-2',
    namespace: 'default',
    status: 'Ready',
    age: '114d',
    labels: {},
    annotations: {},
    kind: 'Deployment',
  },
  {
    name: 'deployment-3',
    namespace: 'default',
    status: 'Failed',
    age: '1d',
    labels: {},
    annotations: {},
    kind: 'Deployment',
  },
];

const readyStatefulSet = {
  status: { readyReplicas: 2 },
  spec: { replicas: 2 },
  metadata: {
    name: 'statefulSet-2',
    namespace: 'default',
    creationTimestamp: '2023-07-31T11:50:17Z',
    labels: {},
    annotations: {},
  },
};
const failedStatefulSet = {
  status: { readyReplicas: 1 },
  spec: { replicas: 2 },
  metadata: {
    name: 'statefulSet-3',
    namespace: 'default',
    creationTimestamp: '2023-11-21T11:50:59Z',
    labels: {},
    annotations: {},
  },
};

export const k8sStatefulSetsMock = [readyStatefulSet, readyStatefulSet, failedStatefulSet];

export const mockStatefulSetsStats = [
  {
    title: 'Ready',
    value: 2,
  },
  {
    title: 'Failed',
    value: 1,
  },
];

export const mockStatefulSetsTableItems = [
  {
    name: 'statefulSet-2',
    namespace: 'default',
    status: 'Ready',
    age: '114d',
    labels: {},
    annotations: {},
    kind: 'StatefulSet',
  },
  {
    name: 'statefulSet-2',
    namespace: 'default',
    status: 'Ready',
    age: '114d',
    labels: {},
    annotations: {},
    kind: 'StatefulSet',
  },
  {
    name: 'statefulSet-3',
    namespace: 'default',
    status: 'Failed',
    age: '1d',
    labels: {},
    annotations: {},
    kind: 'StatefulSet',
  },
];
