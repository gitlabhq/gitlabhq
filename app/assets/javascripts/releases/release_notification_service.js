import { s__, __, sprintf } from '~/locale';
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

export const deleteReleaseSessionKey = (projectPath) => `deleteRelease:${projectPath}`;

export const putDeleteReleaseNotification = (projectPath, releaseName) => {
  window.sessionStorage.setItem(deleteReleaseSessionKey(projectPath), releaseName);
};

export const popDeleteReleaseNotification = (projectPath) => {
  const key = deleteReleaseSessionKey(projectPath);
  const deletedRelease = window.sessionStorage.getItem(key);

  if (deletedRelease) {
    createAlert({
      message: sprintf(__('Release %{deletedRelease} has been successfully deleted.'), {
        deletedRelease,
      }),
      variant: VARIANT_SUCCESS,
    });
    window.sessionStorage.removeItem(key);
  }
};
