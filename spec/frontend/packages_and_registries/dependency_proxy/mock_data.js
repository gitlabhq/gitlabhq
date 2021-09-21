export const proxyData = () => ({
  name: 'Gitlab Org',
  dependencyProxyBlobCount: 2,
  dependencyProxyTotalSize: '1024 Bytes',
  dependencyProxyImagePrefix: 'gdk.test:3000/groups/gitlab-org/dependency_proxy/containers',
  dependencyProxyManifests: { nodes: [], __typename: 'DependencyProxyManifestConnection' },
  dependencyProxyBlobs: { nodes: [], __typename: 'DependencyProxyBlobConnection' },
});
export const proxyDetailsQuery = () => ({
  data: {
    group: {
      ...proxyData(),
      __typename: 'Group',
    },
  },
});
