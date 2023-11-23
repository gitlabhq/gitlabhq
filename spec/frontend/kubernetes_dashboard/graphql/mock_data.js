const runningPod = { status: { phase: 'Running' } };
const pendingPod = { status: { phase: 'Pending' } };
const succeededPod = { status: { phase: 'Succeeded' } };
const failedPod = { status: { phase: 'Failed' } };

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
