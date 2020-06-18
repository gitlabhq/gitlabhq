export const dockerBuildCommand = state => {
  /* eslint-disable @gitlab/require-i18n-strings */
  return `docker build -t ${state.config.repositoryUrl} .`;
};

export const dockerPushCommand = state => {
  /* eslint-disable @gitlab/require-i18n-strings */
  return `docker push ${state.config.repositoryUrl}`;
};

export const dockerLoginCommand = state => {
  /* eslint-disable @gitlab/require-i18n-strings */
  return `docker login ${state.config.registryHostUrlWithPort}`;
};

export const showGarbageCollection = state => {
  return state.showGarbageCollectionTip && state.config.isAdmin;
};
