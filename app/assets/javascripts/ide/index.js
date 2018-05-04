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

// tell webpack to load assets from origin so that web workers don't break
export function resetServiceWorkersPublicPath() {
  // __webpack_public_path__ is a global variable that can be used to adjust
  // the webpack publicPath setting at runtime.
  // see: https://webpack.js.org/guides/public-path/
  const relativeRootPath = (gon && gon.relative_url_root) || '';
  const webpackAssetPath = `${relativeRootPath}/assets/webpack/`;
  __webpack_public_path__ = webpackAssetPath; // eslint-disable-line camelcase
}
