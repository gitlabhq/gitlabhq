export const proxyData = () => ({
  dependencyProxyBlobCount: 2,
  dependencyProxyTotalSize: '1024 Bytes',
  dependencyProxyImagePrefix: 'gdk.test:3000/private-group/dependency_proxy/containers',
  dependencyProxySetting: { enabled: true, __typename: 'DependencyProxySetting' },
});

export const proxySettings = (extend = {}) => ({ enabled: true, ...extend });

export const proxyDetailsQuery = ({ extendSettings = {} } = {}) => ({
  data: {
    group: {
      ...proxyData(),
      __typename: 'Group',
      dependencyProxySetting: {
        ...proxySettings(extendSettings),
        __typename: 'DependencyProxySetting',
      },
    },
  },
});
