export function getDerivedMergeRequestInformation({ endpoint } = {}) {
  const mrPath = endpoint
    ?.split('/')
    .slice(0, -1)
    .join('/');

  return {
    mrPath,
  };
}
