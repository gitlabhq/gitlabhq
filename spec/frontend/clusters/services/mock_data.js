const CLUSTERS_MOCK_DATA = {
  GET: {
    '/gitlab-org/gitlab-shell/clusters/1/status.json': {
      data: {
        status: 'errored',
        status_reason: 'Failed to request to CloudPlatform.',
      },
    },
    '/gitlab-org/gitlab-shell/clusters/2/status.json': {
      data: {
        status: 'errored',
        status_reason: 'Failed to request to CloudPlatform.',
      },
    },
  },
  POST: {},
};

export { CLUSTERS_MOCK_DATA };
