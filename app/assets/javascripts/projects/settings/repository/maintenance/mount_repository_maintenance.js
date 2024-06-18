import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import RemoveBlobs from '~/projects/settings/repository/maintenance/remove_blobs.vue';
import RedactText from '~/projects/settings/repository/maintenance/redact_text.vue';

const mountRemoveBlobs = () => {
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
};

const mountRedactText = () => {
  const redactTextEl = document.querySelector('.js-maintenance-redact-text');
  if (!redactTextEl) return false;

  const { projectPath, housekeepingPath } = redactTextEl.dataset;

  return new Vue({
    el: redactTextEl,
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    provide: { projectPath, housekeepingPath },
    render(createElement) {
      return createElement(RedactText);
    },
  });
};

export default function mountRepositoryMaintenance() {
  mountRemoveBlobs();
  mountRedactText();
}
