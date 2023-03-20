import { s__, sprintf } from '~/locale';
import { createAlert, VARIANT_SUCCESS } from '~/alert';

const createReleaseSessionKey = (projectPath) => `createRelease:${projectPath}`;

export const putCreateReleaseNotification = (projectPath, releaseName) => {
  window.sessionStorage.setItem(createReleaseSessionKey(projectPath), releaseName);
};

export const popCreateReleaseNotification = (projectPath) => {
  const key = createReleaseSessionKey(projectPath);
  const createdRelease = window.sessionStorage.getItem(key);

  if (createdRelease) {
    createAlert({
      message: sprintf(s__('Release|Release %{createdRelease} has been successfully created.'), {
        createdRelease,
      }),
      variant: VARIANT_SUCCESS,
    });
    window.sessionStorage.removeItem(key);
  }
};
