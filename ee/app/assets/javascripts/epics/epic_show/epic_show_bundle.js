import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import EpicShowApp from './components/epic_show_app.vue';

export default () => {
  const el = document.querySelector('#epic-show-app');
  const metaData = convertObjectPropsToCamelCase(JSON.parse(el.dataset.meta));
  const initialData = JSON.parse(el.dataset.initial);

  const props = Object.assign({}, initialData, metaData, el.dataset);

  return new Vue({
    el,
    components: {
      'epic-show-app': EpicShowApp,
    },
    render: createElement => createElement('epic-show-app', {
      props,
    }),
  });
};
