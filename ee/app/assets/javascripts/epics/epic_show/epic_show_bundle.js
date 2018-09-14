import Vue from 'vue';
import Cookies from 'js-cookie';
import bp from '~/breakpoints';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import EpicShowApp from './components/epic_show_app.vue';

export default () => {
  const el = document.querySelector('#epic-show-app');
  const metaData = convertObjectPropsToCamelCase(JSON.parse(el.dataset.meta));
  const initialData = JSON.parse(el.dataset.initial);

  // Collapse the sidebar on mobile screens by default
  const bpBreakpoint = bp.getBreakpointSize();
  if (bpBreakpoint === 'xs' || bpBreakpoint === 'sm') {
    Cookies.set('collapsed_gutter', true);
  }

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
