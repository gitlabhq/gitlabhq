import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';

import { GlSkeletonLoader } from '@gitlab/ui';

import createState from '~/static_site_editor/store/state';

import StaticSiteEditor from '~/static_site_editor/components/static_site_editor.vue';
import EditArea from '~/static_site_editor/components/edit_area.vue';
import PublishToolbar from '~/static_site_editor/components/publish_toolbar.vue';

const localVue = createLocalVue();

localVue.use(Vuex);

describe('StaticSiteEditor', () => {
  let wrapper;
  let store;
  let loadContentActionMock;
  let setContentActionMock;

  const buildStore = ({ initialState, getters } = {}) => {
    loadContentActionMock = jest.fn();
    setContentActionMock = jest.fn();

    store = new Vuex.Store({
      state: createState(initialState),
      getters: {
        isContentLoaded: () => false,
        contentChanged: () => false,
        ...getters,
      },
      actions: {
        loadContent: loadContentActionMock,
        setContent: setContentActionMock,
      },
    });
  };
  const buildContentLoadedStore = ({ initialState, getters } = {}) => {
    buildStore({
      initialState,
      getters: {
        isContentLoaded: () => true,
        ...getters,
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
  const findPublishToolbar = () => wrapper.find(PublishToolbar);
  const findSkeletonLoader = () => wrapper.find(GlSkeletonLoader);

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

    it('does not render toolbar', () => {
      expect(findPublishToolbar().exists()).toBe(false);
    });
  });

  describe('when content is loaded', () => {
    const content = 'edit area content';

    beforeEach(() => {
      buildStore({ initialState: { content }, getters: { isContentLoaded: () => true } });
      buildWrapper();
    });

    it('renders the edit area', () => {
      expect(findEditArea().exists()).toBe(true);
    });

    it('does not render skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });

    it('passes page content to edit area', () => {
      expect(findEditArea().props('value')).toBe(content);
    });

    it('renders toolbar', () => {
      expect(findPublishToolbar().exists()).toBe(true);
    });
  });

  it('sets toolbar as saveable when content changes', () => {
    buildContentLoadedStore({
      getters: {
        contentChanged: () => true,
      },
    });
    buildWrapper();

    expect(findPublishToolbar().props('saveable')).toBe(true);
  });

  it('displays skeleton loader when loading content', () => {
    buildStore({ initialState: { isLoadingContent: true } });
    buildWrapper();

    expect(findSkeletonLoader().exists()).toBe(true);
  });

  it('dispatches load content action', () => {
    expect(loadContentActionMock).toHaveBeenCalled();
  });

  it('dispatches setContent action when edit area emits input event', () => {
    const content = 'new content';

    buildContentLoadedStore();
    buildWrapper();

    findEditArea().vm.$emit('input', content);

    expect(setContentActionMock).toHaveBeenCalledWith(expect.anything(), content, undefined);
  });
});
