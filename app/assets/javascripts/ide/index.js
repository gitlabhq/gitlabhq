import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import ide from './components/ide.vue';
import store from './stores';
import router from './ide_router';

Vue.use(Translate);

export function initIde(el) {
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

export function resetServiceWorkersPublicPath() {
  // tell webpack to load assets from origin so that web workers don't break
  const relativeRootPath = (gon && gon.relative_url_root) || '';
  const webpackAssetPath = `${relativeRootPath}/assets/webpack/`;
  __webpack_public_path__ = webpackAssetPath; // eslint-disable-line camelcase
}
