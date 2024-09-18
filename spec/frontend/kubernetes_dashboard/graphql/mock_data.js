const runningPod = {
  status: { phase: 'Running', ready: true, restartCount: 4 },
  metadata: {
    name: 'pod-1',
    namespace: 'default',
    creationTimestamp: '2023-07-31T11:50:17Z',
    labels: { key: 'value' },
    annotations: { annotation: 'text', another: 'text' },
  },
  spec: { restartPolicy: 'Never', terminationGracePeriodSeconds: 30 },
  __typename: 'LocalWorkloadItem',
};
const pendingPod = {
  status: { phase: 'Pending' },
  metadata: {
    name: 'pod-2',
    namespace: 'new-namespace',
    creationTimestamp: '2023-11-21T11:50:59Z',
    labels: { key: 'value' },
    annotations: { annotation: 'text', another: 'text' },
  },
  spec: {},
  __typename: 'LocalWorkloadItem',
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
  spec: {},
  __typename: 'LocalWorkloadItem',
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
  spec: {},
  __typename: 'LocalWorkloadItem',
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
    spec: { restartPolicy: 'Never', terminationGracePeriodSeconds: 30 },
    fullStatus: { phase: 'Running', ready: true, restartCount: 4 },
  },
  {
    name: 'pod-1',
    namespace: 'default',
    status: 'Running',
    age: '114d',
    labels: { key: 'value' },
    annotations: { annotation: 'text', another: 'text' },
    kind: 'Pod',
    spec: {},
    fullStatus: { phase: 'Running', ready: true, restartCount: 4 },
  },
  {
    name: 'pod-2',
    namespace: 'new-namespace',
    status: 'Pending',
    age: '1d',
    labels: { key: 'value' },
    annotations: { annotation: 'text', another: 'text' },
    kind: 'Pod',
    spec: {},
  },
  {
    name: 'pod-3',
    namespace: 'default',
    status: 'Succeeded',
    age: '114d',
    labels: {},
    annotations: {},
    kind: 'Pod',
    spec: {},
  },
  {
    name: 'pod-4',
    namespace: 'default',
    status: 'Failed',
    age: '1d',
    labels: {},
    annotations: {},
    kind: 'Pod',
    spec: {},
  },
  {
    name: 'pod-4',
    namespace: 'default',
    status: 'Failed',
    age: '1d',
    labels: {},
    annotations: {},
    kind: 'Pod',
    spec: {},
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
  spec: {},
  __typename: 'LocalWorkloadItem',
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
  spec: {},
  __typename: 'LocalWorkloadItem',
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
  spec: {},
  __typename: 'LocalWorkloadItem',
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
  __typename: 'LocalWorkloadItem',
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
  __typename: 'LocalWorkloadItem',
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

export const k8sReplicaSetsMock = [readyStatefulSet, readyStatefulSet, failedStatefulSet];

export const mockReplicaSetsTableItems = mockStatefulSetsTableItems.map((item) => {
  return { ...item, kind: 'ReplicaSet' };
});

const readyDaemonSet = {
  status: { numberMisscheduled: 0, numberReady: 2, desiredNumberScheduled: 2 },
  metadata: {
    name: 'daemonSet-1',
    namespace: 'default',
    creationTimestamp: '2023-07-31T11:50:17Z',
    labels: {},
    annotations: {},
  },
  spec: {},
  __typename: 'LocalWorkloadItem',
};

const failedDaemonSet = {
  status: { numberMisscheduled: 1, numberReady: 1, desiredNumberScheduled: 2 },
  metadata: {
    name: 'daemonSet-2',
    namespace: 'default',
    creationTimestamp: '2023-11-21T11:50:59Z',
    labels: {},
    annotations: {},
  },
  spec: {},
  __typename: 'LocalWorkloadItem',
};

export const mockDaemonSetsStats = [
  {
    title: 'Ready',
    value: 1,
  },
  {
    title: 'Failed',
    value: 1,
  },
];

export const mockDaemonSetsTableItems = [
  {
    name: 'daemonSet-1',
    namespace: 'default',
    status: 'Ready',
    age: '114d',
    labels: {},
    annotations: {},
    kind: 'DaemonSet',
  },
  {
    name: 'daemonSet-2',
    namespace: 'default',
    status: 'Failed',
    age: '1d',
    labels: {},
    annotations: {},
    kind: 'DaemonSet',
  },
];

export const k8sDaemonSetsMock = [readyDaemonSet, failedDaemonSet];

const completedJob = {
  status: { failed: 0, succeeded: 1 },
  spec: { completions: 1 },
  metadata: {
    name: 'job-1',
    namespace: 'default',
    creationTimestamp: '2023-07-31T11:50:17Z',
    labels: {},
    annotations: {},
  },
  __typename: 'LocalWorkloadItem',
};

const failedJob = {
  status: { failed: 1, succeeded: 1 },
  spec: { completions: 2 },
  metadata: {
    name: 'job-2',
    namespace: 'default',
    creationTimestamp: '2023-11-21T11:50:59Z',
    labels: {},
    annotations: {},
  },
  __typename: 'LocalWorkloadItem',
};

const anotherFailedJob = {
  status: { failed: 0, succeeded: 1 },
  spec: { completions: 2 },
  metadata: {
    name: 'job-3',
    namespace: 'default',
    creationTimestamp: '2023-11-21T11:50:59Z',
    labels: {},
    annotations: {},
  },
  __typename: 'LocalWorkloadItem',
};

export const mockJobsStats = [
  {
    title: 'Completed',
    value: 1,
  },
  {
    title: 'Failed',
    value: 2,
  },
];

export const mockJobsTableItems = [
  {
    name: 'job-1',
    namespace: 'default',
    status: 'Completed',
    age: '114d',
    labels: {},
    annotations: {},
    kind: 'Job',
  },
  {
    name: 'job-2',
    namespace: 'default',
    status: 'Failed',
    age: '1d',
    labels: {},
    annotations: {},
    kind: 'Job',
  },
  {
    name: 'job-3',
    namespace: 'default',
    status: 'Failed',
    age: '1d',
    labels: {},
    annotations: {},
    kind: 'Job',
  },
];

export const k8sJobsMock = [completedJob, failedJob, anotherFailedJob];

const readyCronJob = {
  status: { active: 0, lastScheduleTime: '2023-07-31T11:50:17Z' },
  spec: { suspend: 0 },
  metadata: {
    name: 'cronJob-1',
    namespace: 'default',
    creationTimestamp: '2023-07-31T11:50:17Z',
    labels: {},
    annotations: {},
  },
  __typename: 'LocalWorkloadItem',
};

const suspendedCronJob = {
  status: { active: 0, lastScheduleTime: null },
  spec: { suspend: 1 },
  metadata: {
    name: 'cronJob-2',
    namespace: 'default',
    creationTimestamp: '2023-11-21T11:50:59Z',
    labels: {},
    annotations: {},
  },
  __typename: 'LocalWorkloadItem',
};

const failedCronJob = {
  status: { active: 1, lastScheduleTime: null },
  spec: { suspend: 0 },
  metadata: {
    name: 'cronJob-3',
    namespace: 'default',
    creationTimestamp: '2023-11-21T11:50:59Z',
    labels: {},
    annotations: {},
  },
  __typename: 'LocalWorkloadItem',
};

export const mockCronJobsStats = [
  {
    title: 'Ready',
    value: 1,
  },
  {
    title: 'Failed',
    value: 1,
  },
  {
    title: 'Suspended',
    value: 1,
  },
];

export const mockCronJobsTableItems = [
  {
    name: 'cronJob-1',
    namespace: 'default',
    status: 'Ready',
    age: '114d',
    labels: {},
    annotations: {},
    kind: 'CronJob',
  },
  {
    name: 'cronJob-2',
    namespace: 'default',
    status: 'Suspended',
    age: '1d',
    labels: {},
    annotations: {},
    kind: 'CronJob',
  },
  {
    name: 'cronJob-3',
    namespace: 'default',
    status: 'Failed',
    age: '1d',
    labels: {},
    annotations: {},
    kind: 'CronJob',
  },
];

export const k8sCronJobsMock = [readyCronJob, suspendedCronJob, failedCronJob];

export const k8sServicesMock = [
  {
    metadata: {
      name: 'my-first-service',
      namespace: 'default',
      creationTimestamp: '2023-07-31T11:50:17Z',
      labels: {},
      annotations: {},
    },
    spec: {
      ports: [
        {
          name: 'https',
          protocol: 'TCP',
          port: 443,
          targetPort: 8443,
        },
      ],
      clusterIP: '10.96.0.1',
      externalIP: '-',
      type: 'ClusterIP',
    },
    status: {},
    __typename: 'LocalWorkloadItem',
  },
  {
    metadata: {
      name: 'my-second-service',
      namespace: 'default',
      creationTimestamp: '2023-11-21T11:50:59Z',
      labels: {},
      annotations: {},
    },
    spec: {
      ports: [
        {
          name: 'http',
          protocol: 'TCP',
          appProtocol: 'http',
          port: 80,
          targetPort: 'http',
          nodePort: 31989,
        },
        {
          name: 'https',
          protocol: 'TCP',
          appProtocol: 'https',
          port: 443,
          targetPort: 'https',
          nodePort: 32679,
        },
      ],
      clusterIP: '10.105.219.238',
      externalIP: '-',
      type: 'NodePort',
    },
    status: {},
    __typename: 'LocalWorkloadItem',
  },
];

export const mockServicesTableItems = [
  {
    name: 'my-first-service',
    namespace: 'default',
    type: 'ClusterIP',
    clusterIP: '10.96.0.1',
    externalIP: '-',
    ports: '443/TCP',
    age: '114d',
    labels: {},
    annotations: {},
    kind: 'Service',
  },
  {
    name: 'my-second-service',
    namespace: 'default',
    type: 'NodePort',
    clusterIP: '10.105.219.238',
    externalIP: '-',
    ports: '80:31989/TCP, 443:32679/TCP',
    age: '1d',
    labels: {},
    annotations: {},
    kind: 'Service',
  },
];

export const k8sEventsMock = [
  {
    type: 'normal',
    source: { component: 'my-component' },
    reason: 'Reason 1',
    message: 'Event 1',
    lastTimestamp: '2023-05-01T10:00:00Z',
    eventTime: '',
  },
  {
    type: 'normal',
    source: { component: 'my-component' },
    reason: 'Reason 2',
    message: 'Event 2',
    lastTimestamp: '',
    eventTime: '2023-05-01T11:00:00Z',
  },
  {
    type: 'normal',
    source: { component: 'my-component' },
    reason: 'Reason 3',
    message: 'Event 3',
    lastTimestamp: '2023-05-01T12:00:00Z',
    eventTime: '',
  },
];
