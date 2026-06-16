import Vue from 'vue';
import VueApollo from 'vue-apollo';
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

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'DeleteButtonRoot',
    apolloProvider,
    provide: { triggerDeleteLocation: 'setting' },
    render(createElement) {
      return createElement(DeleteButton, {
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
    },
  });
};
