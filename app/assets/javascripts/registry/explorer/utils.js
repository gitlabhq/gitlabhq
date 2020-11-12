export const pathGenerator = (imageDetails, ending = '?format=json') => {
  // this method is a temporary workaround, to be removed with graphql implementation
  // https://gitlab.com/gitlab-org/gitlab/-/issues/276432

  const splitPath = imageDetails.path.split('/').reverse();
  const splitName = imageDetails.name ? imageDetails.name.split('/').reverse() : [];
  const basePath = splitPath
    .reduce((acc, curr, index) => {
      if (splitPath[index] !== splitName[index]) {
        acc.unshift(curr);
      }
      return acc;
    }, [])
    .join('/');
  return `/${basePath}/registry/repository/${imageDetails.id}/tags${ending}`;
};
