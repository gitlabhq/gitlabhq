import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { keepAlive } from 'helpers/keep_alive_component_helper';
import { trimText } from 'helpers/text_helper';
import EditorModeDropdown from '~/ide/components/editor_mode_dropdown.vue';
import IdeReview from '~/ide/components/ide_review.vue';
import { createStore } from '~/ide/stores';
import { file } from '../helpers';
import { projectData } from '../mock_data';

Vue.use(Vuex);

describe('IDE review mode', () => {
  let wrapper;
  let store;
  let dispatch;

  beforeEach(() => {
    store = createStore();
    store.state.currentProjectId = 'abcproject';
    store.state.currentBranchId = 'main';
    store.state.projects.abcproject = { ...projectData };
    store.state.trees = {
      ...store.state.trees,
      'abcproject/main': {
        tree: [file('fileName')],
        loading: false,
      },
    };

    dispatch = jest.spyOn(store, 'dispatch');

    wrapper = mount(keepAlive(IdeReview), {
      store,
    });
  });

  const findEditorModeDropdown = () => wrapper.findComponent(EditorModeDropdown);

  it('renders list of files', () => {
    expect(wrapper.text()).toContain('fileName');
  });

  describe('activated', () => {
    beforeEach(async () => {
      store.state.viewer = 'editor';

      await wrapper.vm.reactivate();
    });

    it('re initializes the component', () => {
      expect(dispatch).toHaveBeenCalledWith('updateViewer', 'diff');
    });

    it('updates viewer to "diff" by default', () => {
      expect(store.state.viewer).toBe('diff');
    });

    describe('merge request is defined', () => {
      beforeEach(async () => {
        store.state.currentMergeRequestId = '1';
        store.state.projects.abcproject.mergeRequests['1'] = {
          iid: 123,
          web_url: 'testing123',
        };

        await wrapper.vm.reactivate();
      });

      it('updates viewer to "mrdiff"', () => {
        expect(store.state.viewer).toBe('mrdiff');
      });
    });
  });

  describe('merge request', () => {
    beforeEach(async () => {
      store.state.currentMergeRequestId = '1';
      store.state.projects.abcproject.mergeRequests['1'] = {
        iid: 123,
        web_url: 'testing123',
      };

      await nextTick();
    });

    it('renders edit dropdown', () => {
      expect(findEditorModeDropdown().exists()).toBe(true);
    });

    it('renders merge request link & IID', async () => {
      store.state.viewer = 'mrdiff';

      await nextTick();

      expect(trimText(wrapper.text())).toContain('Merge request (!123)');
    });

    it('changes text to latest changes when viewer is not mrdiff', async () => {
      store.state.viewer = 'diff';

      await nextTick();

      expect(wrapper.text()).toContain('Latest changes');
    });
  });
});
