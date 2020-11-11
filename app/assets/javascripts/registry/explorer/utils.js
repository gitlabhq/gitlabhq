export const pathGenerator = (imageDetails, ending = '?format=json') => {
  // this method is a temporary workaround, to be removed with graphql implementation
  // https://gitlab.com/gitlab-org/gitlab/-/issues/276432
  const basePath = imageDetails.name
    ? imageDetails.path.replace(`/${imageDetails.name}`, '')
    : imageDetails.path;
  return `/${basePath}/registry/repository/${imageDetails.id}/tags${ending}`;
};
