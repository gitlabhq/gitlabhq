import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import RemoveBlobs from '~/projects/settings/repository/maintenance/remove_blobs.vue';
import RedactText from '~/projects/settings/repository/maintenance/redact_text.vue';

const mountRemoveBlobs = () => {
  const removeBlobsEl = document.querySelector('.js-maintenance-remove-blobs');
  if (!removeBlobsEl) return false;

  const { projectPath, housekeepingPath } = removeBlobsEl.dataset;

  return initVueApp({
    el: removeBlobsEl,
    name: 'RemoveBlobsRoot',
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    provide: { projectPath, housekeepingPath },
    component: RemoveBlobs,
  });
};

const mountRedactText = () => {
  const redactTextEl = document.querySelector('.js-maintenance-redact-text');
  if (!redactTextEl) return false;

  const { projectPath, housekeepingPath } = redactTextEl.dataset;

  return initVueApp({
    el: redactTextEl,
    name: 'RedactTextRoot',
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    provide: { projectPath, housekeepingPath },
    component: RedactText,
  });
};

export default function mountRepositoryMaintenance() {
  mountRemoveBlobs();
  mountRedactText();
}
