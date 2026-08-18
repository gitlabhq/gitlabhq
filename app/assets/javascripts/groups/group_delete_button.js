import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import DeleteButton from './components/delete_button.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const initGroupDeleteButton = () => {
  const el = document.querySelector('#js-group-delete-button');

  if (!el) return;

  const {
    formPath,
    confirmPhrase,
    fullName,
    subgroupsCount,
    projectsCount,
    markedForDeletion,
    permanentDeletionDate,
  } = el.dataset;

  initVueApp({
    el,
    name: 'GroupDeleteButtonRoot',
    apolloProvider,
    provide: { triggerDeleteLocation: 'setting' },
    component: DeleteButton,
    props: {
      formPath,
      confirmPhrase,
      fullName,
      subgroupsCount: parseInt(subgroupsCount, 10),
      projectsCount: parseInt(projectsCount, 10),
      markedForDeletion: parseBoolean(markedForDeletion),
      permanentDeletionDate,
    },
  });
};
