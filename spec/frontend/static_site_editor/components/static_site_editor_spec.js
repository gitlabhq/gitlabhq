import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';

import { GlSkeletonLoader } from '@gitlab/ui';

import createState from '~/static_site_editor/store/state';

import StaticSiteEditor from '~/static_site_editor/components/static_site_editor.vue';
import EditArea from '~/static_site_editor/components/edit_area.vue';

const localVue = createLocalVue();

localVue.use(Vuex);

describe('StaticSiteEditor', () => {
  let wrapper;
  let store;
  let loadContentActionMock;

  const buildStore = (initialState = {}) => {
    loadContentActionMock = jest.fn();

    store = new Vuex.Store({
      state: createState(initialState),
      actions: {
        loadContent: loadContentActionMock,
      },
    });
  };

  const buildWrapper = () => {
    wrapper = shallowMount(StaticSiteEditor, {
      localVue,
      store,
    });
  };

  const findEditArea = () => wrapper.find(EditArea);

  beforeEach(() => {
    buildStore();
    buildWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when content is not loaded', () => {
    it('does not render edit area', () => {
      expect(findEditArea().exists()).toBe(false);
    });
  });

  describe('when content is loaded', () => {
    const content = 'edit area content';

    beforeEach(() => {
      buildStore({ content, isContentLoaded: true });
      buildWrapper();
    });

    it('renders the edit area', () => {
      expect(findEditArea().exists()).toBe(true);
    });

    it('passes page content to edit area', () => {
      expect(findEditArea().props('value')).toBe(content);
    });
  });

  it('displays skeleton loader while loading content', () => {
    buildStore({ isLoadingContent: true });
    buildWrapper();

    expect(wrapper.find(GlSkeletonLoader).exists()).toBe(true);
  });

  it('dispatches load content action', () => {
    expect(loadContentActionMock).toHaveBeenCalled();
  });
});
