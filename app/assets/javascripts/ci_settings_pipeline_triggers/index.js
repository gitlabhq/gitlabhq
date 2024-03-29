import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import TriggersList from './components/triggers_list.vue';

const parseJsonArray = (triggers) => {
  try {
    return convertObjectPropsToCamelCase(JSON.parse(triggers), { deep: true });
  } catch {
    return [];
  }
};

export default (containerId = 'js-ci-pipeline-triggers-list') => {
  const containerEl = document.getElementById(containerId);

  if (!containerEl) {
    return null;
  }

  const triggers = parseJsonArray(containerEl.dataset.triggers);

  return new Vue({
    el: containerEl,
    components: {
      TriggersList,
    },
    render(h) {
      return h(TriggersList, {
        props: {
          triggers,
        },
      });
    },
  });
};
