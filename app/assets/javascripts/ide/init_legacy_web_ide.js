// legacyWebIDE.js
import { identity } from 'lodash';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import { parseBoolean } from '../lib/utils/common_utils';
import { DEFAULT_BRANCH } from './constants';
import ide from './components/ide.vue';
import { createRouter } from './ide_router';
import { DEFAULT_THEME } from './lib/themes';
import { createStore } from './stores';

export const initLegacyWebIDE = (el, options = {}) => {
  if (!el) return null;

  const { rootComponent = ide, extendStore = identity } = options;

  const store = createStore();
  const project = JSON.parse(el.dataset.project);
  store.dispatch('setProject', { project });

  // fire and forget fetching non-critical project info
  store.dispatch('fetchProjectPermissions');

  const router = createRouter(store, el.dataset.defaultBranch || DEFAULT_BRANCH);

  return new Vue({
    el,
    store: extendStore(store, el),
    router,
    created() {
      this.setEmptyStateSvgs({
        emptyStateSvgPath: el.dataset.emptyStateSvgPath,
        noChangesStateSvgPath: el.dataset.noChangesStateSvgPath,
        committedStateSvgPath: el.dataset.committedStateSvgPath,
        pipelinesEmptyStateSvgPath: el.dataset.pipelinesEmptyStateSvgPath,
        switchEditorSvgPath: el.dataset.switchEditorSvgPath,
      });
      this.setLinks({
        webIDEHelpPagePath: el.dataset.webIdeHelpPagePath,
        newWebIDEHelpPagePath: el.dataset.newWebIdeHelpPagePath,
        forkInfo: el.dataset.forkInfo ? JSON.parse(el.dataset.forkInfo) : null,
      });
      this.init({
        renderWhitespaceInCode: parseBoolean(el.dataset.renderWhitespaceInCode),
        editorTheme: window.gon?.user_color_scheme || DEFAULT_THEME,
        previewMarkdownPath: el.dataset.previewMarkdownPath,
        userPreferencesPath: el.dataset.userPreferencesPath,
      });
    },
    beforeDestroy() {
      // This helps tests do Singleton cleanups which we don't really have responsibility to know about here.
      this.$emit('destroy');
    },
    methods: {
      ...mapActions(['setEmptyStateSvgs', 'setLinks', 'init']),
    },
    render(createElement) {
      return createElement(rootComponent);
    },
  });
};
