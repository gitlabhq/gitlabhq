export const decodeAndParse = param => JSON.parse(window.atob(param));

// eslint-disable-next-line @gitlab/require-i18n-strings
export const pathGenerator = (imageDetails, ending = 'tags?format=json') => {
  // this method is a temporary workaround, to be removed with graphql implementation
  // https://gitlab.com/gitlab-org/gitlab/-/issues/276432
  const basePath = imageDetails.path.replace(`/${imageDetails.name}`, '');
  return `/${basePath}/registry/repository/${imageDetails.id}/${ending}`;
};
