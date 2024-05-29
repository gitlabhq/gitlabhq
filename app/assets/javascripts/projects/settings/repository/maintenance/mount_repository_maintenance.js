import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import RemoveBlobs from '~/projects/settings/repository/maintenance/remove_blobs.vue';

export default function mountRepositoryMaintenance() {
  const removeBlobsEl = document.querySelector('.js-maintenance-remove-blobs');
  if (!removeBlobsEl) return false;

  const { projectPath, housekeepingPath } = removeBlobsEl.dataset;

  return new Vue({
    el: removeBlobsEl,
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    provide: { projectPath, housekeepingPath },
    render(createElement) {
      return createElement(RemoveBlobs);
    },
  });
}
