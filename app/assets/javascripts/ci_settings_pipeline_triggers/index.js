import VueApollo from 'vue-apollo';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { defaultClient } from '~/graphql_shared/issuable_client';
import TriggersList from './components/triggers_list.vue';

const parseJsonArray = (triggers) => {
  try {
    return convertObjectPropsToCamelCase(JSON.parse(triggers), { deep: true });
  } catch {
    return [];
  }
};

const apolloProvider = new VueApollo({
  defaultClient,
});

export default (containerId = 'js-ci-pipeline-triggers-list') => {
  const containerEl = document.getElementById(containerId);

  if (!containerEl) {
    return null;
  }

  const initTriggers = parseJsonArray(containerEl.dataset.triggers);

  return initVueApp({
    el: containerEl,
    name: 'TriggersListRoot',
    apolloProvider,
    component: TriggersList,
    props: {
      initTriggers,
    },
  });
};
