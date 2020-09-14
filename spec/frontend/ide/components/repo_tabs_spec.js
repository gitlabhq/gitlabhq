import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import { createStore } from '~/ide/stores';
import RepoTabs from '~/ide/components/repo_tabs.vue';
import { file } from '../helpers';

const localVue = createLocalVue();
localVue.use(Vuex);

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
      localVue,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders a list of tabs', done => {
    store.state.openFiles[0].active = true;

    wrapper.vm.$nextTick(() => {
      const tabs = [...wrapper.vm.$el.querySelectorAll('.multi-file-tab')];

      expect(tabs.length).toEqual(2);
      expect(tabs[0].parentNode.classList.contains('active')).toEqual(true);
      expect(tabs[1].parentNode.classList.contains('active')).toEqual(false);

      done();
    });
  });
});
