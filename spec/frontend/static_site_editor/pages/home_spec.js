import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlSkeletonLoader } from '@gitlab/ui';

import createState from '~/static_site_editor/store/state';

import Home from '~/static_site_editor/pages/home.vue';
import RichContentEditor from '~/vue_shared/components/rich_content_editor/rich_content_editor.vue';
import EditHeader from '~/static_site_editor/components/edit_header.vue';
import InvalidContentMessage from '~/static_site_editor/components/invalid_content_message.vue';
import PublishToolbar from '~/static_site_editor/components/publish_toolbar.vue';
import SubmitChangesError from '~/static_site_editor/components/submit_changes_error.vue';
import SavedChangesMessage from '~/static_site_editor/components/saved_changes_message.vue';

import {
  returnUrl,
  sourceContent,
  sourceContentTitle,
  savedContentMeta,
  submitChangesError,
} from '../mock_data';

const localVue = createLocalVue();

localVue.use(Vuex);

describe('static_site_editor/pages/home', () => {
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

  const buildWrapper = (data = { appData: { isSupportedContent: true } }) => {
    wrapper = shallowMount(Home, {
      localVue,
      store,
      provide: {
        glFeatures: { richContentEditor: true },
      },
      data() {
        return data;
      },
    });
  };

  const findRichContentEditor = () => wrapper.find(RichContentEditor);
  const findEditHeader = () => wrapper.find(EditHeader);
  const findInvalidContentMessage = () => wrapper.find(InvalidContentMessage);
  const findPublishToolbar = () => wrapper.find(PublishToolbar);
  const findSkeletonLoader = () => wrapper.find(GlSkeletonLoader);
  const findSubmitChangesError = () => wrapper.find(SubmitChangesError);
  const findSavedChangesMessage = () => wrapper.find(SavedChangesMessage);

  beforeEach(() => {
    buildStore();
    buildWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the saved changes message when changes are submitted successfully', () => {
    buildStore({ initialState: { returnUrl, savedContentMeta } });
    buildWrapper();

    expect(findSavedChangesMessage().exists()).toBe(true);
    expect(findSavedChangesMessage().props()).toEqual({
      returnUrl,
      ...savedContentMeta,
    });
  });

  describe('when content is not loaded', () => {
    it('does not render rich content editor', () => {
      expect(findRichContentEditor().exists()).toBe(false);
    });

    it('does not render edit header', () => {
      expect(findEditHeader().exists()).toBe(false);
    });

    it('does not render toolbar', () => {
      expect(findPublishToolbar().exists()).toBe(false);
    });

    it('does not render saved changes message', () => {
      expect(findSavedChangesMessage().exists()).toBe(false);
    });
  });

  describe('when content is loaded', () => {
    const content = sourceContent;
    const title = sourceContentTitle;

    beforeEach(() => {
      buildContentLoadedStore({ initialState: { content, title } });
      buildWrapper();
    });

    it('renders the rich content editor', () => {
      expect(findRichContentEditor().exists()).toBe(true);
    });

    it('renders the edit header', () => {
      expect(findEditHeader().exists()).toBe(true);
    });

    it('does not render skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });

    it('passes page content to the rich content editor', () => {
      expect(findRichContentEditor().props('value')).toBe(content);
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
    buildWrapper({ appData: { isSupportedContent: false } });

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

  it('dispatches setContent action when rich content editor emits input event', () => {
    buildContentLoadedStore();
    buildWrapper();

    findRichContentEditor().vm.$emit('input', sourceContent);

    expect(setContentActionMock).toHaveBeenCalledWith(expect.anything(), sourceContent, undefined);
  });

  it('dispatches submitChanges action when toolbar emits submit event', () => {
    buildContentLoadedStore();
    buildWrapper();
    findPublishToolbar().vm.$emit('submit');

    expect(submitChangesActionMock).toHaveBeenCalled();
  });
});
