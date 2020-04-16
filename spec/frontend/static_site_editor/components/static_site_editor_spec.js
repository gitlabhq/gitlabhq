import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';

import { GlSkeletonLoader } from '@gitlab/ui';

import createState from '~/static_site_editor/store/state';

import StaticSiteEditor from '~/static_site_editor/components/static_site_editor.vue';
import EditArea from '~/static_site_editor/components/edit_area.vue';
import EditHeader from '~/static_site_editor/components/edit_header.vue';
import InvalidContentMessage from '~/static_site_editor/components/invalid_content_message.vue';
import PublishToolbar from '~/static_site_editor/components/publish_toolbar.vue';
import SubmitChangesError from '~/static_site_editor/components/submit_changes_error.vue';

import { sourceContent, sourceContentTitle, submitChangesError } from '../mock_data';

const localVue = createLocalVue();

localVue.use(Vuex);

describe('StaticSiteEditor', () => {
  let wrapper;
  let store;
  let loadContentActionMock;
  let setContentActionMock;
  let submitChangesActionMock;
  let dismissSubmitChangesErrorActionMock;

  const buildStore = ({ initialState, getters } = {}) => {
    loadContentActionMock = jest.fn();
    setContentActionMock = jest.fn();
    submitChangesActionMock = jest.fn();
    dismissSubmitChangesErrorActionMock = jest.fn();

    store = new Vuex.Store({
      state: createState({
        isSupportedContent: true,
        ...initialState,
      }),
      getters: {
        contentChanged: () => false,
        ...getters,
      },
      actions: {
        loadContent: loadContentActionMock,
        setContent: setContentActionMock,
        submitChanges: submitChangesActionMock,
        dismissSubmitChangesError: dismissSubmitChangesErrorActionMock,
      },
    });
  };
  const buildContentLoadedStore = ({ initialState, getters } = {}) => {
    buildStore({
      initialState: {
        isContentLoaded: true,
        ...initialState,
      },
      getters: {
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
  const findEditHeader = () => wrapper.find(EditHeader);
  const findInvalidContentMessage = () => wrapper.find(InvalidContentMessage);
  const findPublishToolbar = () => wrapper.find(PublishToolbar);
  const findSkeletonLoader = () => wrapper.find(GlSkeletonLoader);
  const findSubmitChangesError = () => wrapper.find(SubmitChangesError);

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

    it('does not render edit header', () => {
      expect(findEditHeader().exists()).toBe(false);
    });

    it('does not render toolbar', () => {
      expect(findPublishToolbar().exists()).toBe(false);
    });
  });

  describe('when content is loaded', () => {
    const content = sourceContent;
    const title = sourceContentTitle;

    beforeEach(() => {
      buildContentLoadedStore({ initialState: { content, title } });
      buildWrapper();
    });

    it('renders the edit area', () => {
      expect(findEditArea().exists()).toBe(true);
    });

    it('renders the edit header', () => {
      expect(findEditHeader().exists()).toBe(true);
    });

    it('does not render skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });

    it('passes page content to edit area', () => {
      expect(findEditArea().props('value')).toBe(content);
    });

    it('passes page title to edit header', () => {
      expect(findEditHeader().props('title')).toBe(title);
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

  it('does not display submit changes error when an error does not exist', () => {
    buildContentLoadedStore();
    buildWrapper();

    expect(findSubmitChangesError().exists()).toBe(false);
  });

  it('sets toolbar as saving when saving changes', () => {
    buildContentLoadedStore({
      initialState: {
        isSavingChanges: true,
      },
    });
    buildWrapper();

    expect(findPublishToolbar().props('savingChanges')).toBe(true);
  });

  it('displays invalid content message when content is not supported', () => {
    buildStore({ initialState: { isSupportedContent: false } });
    buildWrapper();

    expect(findInvalidContentMessage().exists()).toBe(true);
  });

  describe('when submitting changes fail', () => {
    beforeEach(() => {
      buildContentLoadedStore({
        initialState: {
          submitChangesError,
        },
      });
      buildWrapper();
    });

    it('displays submit changes error message', () => {
      expect(findSubmitChangesError().exists()).toBe(true);
    });

    it('dispatches submitChanges action when error message emits retry event', () => {
      findSubmitChangesError().vm.$emit('retry');

      expect(submitChangesActionMock).toHaveBeenCalled();
    });

    it('dispatches dismissSubmitChangesError action when error message emits dismiss event', () => {
      findSubmitChangesError().vm.$emit('dismiss');

      expect(dismissSubmitChangesErrorActionMock).toHaveBeenCalled();
    });
  });

  it('dispatches load content action', () => {
    expect(loadContentActionMock).toHaveBeenCalled();
  });

  it('dispatches setContent action when edit area emits input event', () => {
    buildContentLoadedStore();
    buildWrapper();

    findEditArea().vm.$emit('input', sourceContent);

    expect(setContentActionMock).toHaveBeenCalledWith(expect.anything(), sourceContent, undefined);
  });

  it('dispatches submitChanges action when toolbar emits submit event', () => {
    buildContentLoadedStore();
    buildWrapper();
    findPublishToolbar().vm.$emit('submit');

    expect(submitChangesActionMock).toHaveBeenCalled();
  });
});
