import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import RepoTabs from '~/ide/components/repo_tabs.vue';
import { createStore } from '~/ide/stores';
import { file } from '../helpers';

Vue.use(Vuex);

describe('RepoTabs', () => {
  let wrapper;
  let store;

  beforeEach(() => {
    store = createStore();
    store.state.openFiles = [file('open1'), file('open2')];

    wrapper = mount(RepoTabs, {
      propsData: {
        files: store.state.openFiles,
        viewer: 'editor',
        activeFile: file('activeFile'),
      },
      store,
    });
  });

  it('renders a list of tabs', async () => {
    store.state.openFiles[0].active = true;

    await nextTick();
    const tabs = [...wrapper.vm.$el.querySelectorAll('.multi-file-tab')];

    expect(tabs.length).toEqual(2);
    expect(tabs[0].parentNode.classList.contains('active')).toEqual(true);
    expect(tabs[1].parentNode.classList.contains('active')).toEqual(false);
  });
});
