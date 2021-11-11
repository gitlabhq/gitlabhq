export const proxyData = () => ({
  dependencyProxyBlobCount: 2,
  dependencyProxyTotalSize: '1024 Bytes',
  dependencyProxyImagePrefix: 'gdk.test:3000/private-group/dependency_proxy/containers',
  dependencyProxySetting: { enabled: true, __typename: 'DependencyProxySetting' },
});

export const proxySettings = (extend = {}) => ({ enabled: true, ...extend });

export const proxyManifests = () => [
  { createdAt: '2021-09-22T09:45:28Z', imageName: 'alpine:latest' },
  { createdAt: '2021-09-21T09:45:28Z', imageName: 'alpine:stable' },
];

export const pagination = (extend) => ({
  endCursor: 'eyJpZCI6IjIwNSIsIm5hbWUiOiJteS9jb21wYW55L2FwcC9teS1hcHAifQ',
  hasNextPage: true,
  hasPreviousPage: true,
  startCursor: 'eyJpZCI6IjI0NyIsIm5hbWUiOiJ2ZXJzaW9uX3Rlc3QxIn0',
  __typename: 'PageInfo',
  ...extend,
});

export const proxyDetailsQuery = ({ extendSettings = {}, extend } = {}) => ({
  data: {
    group: {
      ...proxyData(),
      __typename: 'Group',
      dependencyProxySetting: {
        ...proxySettings(extendSettings),
        __typename: 'DependencyProxySetting',
      },
      dependencyProxyManifests: {
        nodes: proxyManifests(),
        pageInfo: pagination(),
      },
      ...extend,
    },
  },
});
