import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import DeleteButton from './components/shared/delete_button.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default (selector = '#js-project-delete-button') => {
  const el = document.querySelector(selector);

  if (!el) return;

  const {
    confirmPhrase,
    nameWithNamespace,
    formPath,
    isFork,
    issuesCount,
    mergeRequestsCount,
    forksCount,
    starsCount,
    buttonText,
    markedForDeletion,
    permanentDeletionDate,
  } = el.dataset;

  initVueApp({
    el,
    name: 'DeleteButtonRoot',
    apolloProvider,
    provide: { triggerDeleteLocation: 'setting' },
    component: DeleteButton,
    props: {
      confirmPhrase,
      nameWithNamespace,
      formPath,
      isFork: parseBoolean(isFork),
      issuesCount: parseInt(issuesCount, 10),
      mergeRequestsCount: parseInt(mergeRequestsCount, 10),
      forksCount: parseInt(forksCount, 10),
      starsCount: parseInt(starsCount, 10),
      buttonText,
      markedForDeletion: parseBoolean(markedForDeletion),
      permanentDeletionDate,
    },
  });
};
