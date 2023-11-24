const runningPod = {
  status: { phase: 'Running' },
  metadata: {
    name: 'pod-1',
    namespace: 'default',
    creationTimestamp: '2023-07-31T11:50:17Z',
  },
};
const pendingPod = {
  status: { phase: 'Pending' },
  metadata: {
    name: 'pod-2',
    namespace: 'new-namespace',
    creationTimestamp: '2023-11-21T11:50:59Z',
  },
};
const succeededPod = {
  status: { phase: 'Succeeded' },
  metadata: {
    name: 'pod-3',
    namespace: 'default',
    creationTimestamp: '2023-07-31T11:50:17Z',
  },
};
const failedPod = {
  status: { phase: 'Failed' },
  metadata: {
    name: 'pod-4',
    namespace: 'default',
    creationTimestamp: '2023-11-21T11:50:59Z',
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
  },
  {
    name: 'pod-1',
    namespace: 'default',
    status: 'Running',
    age: '114d',
  },
  {
    name: 'pod-2',
    namespace: 'new-namespace',
    status: 'Pending',
    age: '1d',
  },
  {
    name: 'pod-3',
    namespace: 'default',
    status: 'Succeeded',
    age: '114d',
  },
  {
    name: 'pod-4',
    namespace: 'default',
    status: 'Failed',
    age: '1d',
  },
  {
    name: 'pod-4',
    namespace: 'default',
    status: 'Failed',
    age: '1d',
  },
];
