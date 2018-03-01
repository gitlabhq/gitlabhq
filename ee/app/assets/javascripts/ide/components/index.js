import Vue from 'vue';
import ide from './components/ide.vue';
import store from './stores';
import router from './ide_router';
import Translate from '../vue_shared/translate';

function initIde(el) {
  if (!el) return null;

  return new Vue({
    el,
    store,
    router,
    components: {
      ide,
    },
    render(createElement) {
      return createElement('ide', {
        props: {
          emptyStateSvgPath: el.dataset.emptyStateSvgPath,
          noChangesStateSvgPath: el.dataset.noChangesStateSvgPath,
          committedStateSvgPath: el.dataset.committedStateSvgPath,
        },
      });
    },
  });
}

const ideElement = document.getElementById('ide');

Vue.use(Translate);

initIde(ideElement);
