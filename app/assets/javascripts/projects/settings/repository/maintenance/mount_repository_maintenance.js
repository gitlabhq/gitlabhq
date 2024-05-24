import Vue from 'vue';
import RemoveBlobs from '~/projects/settings/repository/maintenance/remove_blobs.vue';

export default function mountRepositoryMaintenance() {
  const removeBlobsEl = document.querySelector('.js-maintenance-remove-blobs');
  if (!removeBlobsEl) return false;

  return new Vue({
    el: removeBlobsEl,
    render(createElement) {
      return createElement(RemoveBlobs);
    },
  });
}
