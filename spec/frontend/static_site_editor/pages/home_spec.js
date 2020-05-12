import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';

import createState from '~/static_site_editor/store/state';

import Home from '~/static_site_editor/pages/home.vue';

import SkeletonLoader from '~/static_site_editor/components/skeleton_loader.vue';
import EditArea from '~/static_site_editor/components/edit_area.vue';
import InvalidContentMessage from '~/static_site_editor/components/invalid_content_message.vue';
import SubmitChangesError from '~/static_site_editor/components/submit_changes_error.vue';
import SavedChangesMessage from '~/static_site_editor/components/saved_changes_message.vue';

import {
  returnUrl,
  sourceContent as content,
  sourceContentTitle as title,
  savedContentMeta,
  submitChangesError,
} from '../mock_data';

const localVue = createLocalVue();

localVue.use(Vuex);

describe('static_site_editor/pages/home', () => {
  let wrapper;
  let store;
  let $apollo;
  let setContentActionMock;
  let submitChangesActionMock;
  let dismissSubmitChangesErrorActionMock;

  const buildStore = ({ initialState, getters } = {}) => {
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
        setContent: setContentActionMock,
        submitChanges: submitChangesActionMock,
        dismissSubmitChangesError: dismissSubmitChangesErrorActionMock,
      },
    });
  };

  const buildApollo = (queries = {}) => {
    $apollo = {
      queries: {
        sourceContent: {
          loading: false,
        },
        ...queries,
      },
    };
  };

  const buildWrapper = (data = {}) => {
    wrapper = shallowMount(Home, {
      localVue,
      store,
      mocks: {
        $apollo,
      },
      data() {
        return {
          appData: { isSupportedContent: true, returnUrl },
          ...data,
        };
      },
    });
  };

  const findEditArea = () => wrapper.find(EditArea);
  const findInvalidContentMessage = () => wrapper.find(InvalidContentMessage);
  const findSkeletonLoader = () => wrapper.find(SkeletonLoader);
  const findSubmitChangesError = () => wrapper.find(SubmitChangesError);
  const findSavedChangesMessage = () => wrapper.find(SavedChangesMessage);

  beforeEach(() => {
    buildApollo();
    buildStore();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    $apollo = null;
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

  it('does not render the saved changes message when changes are not submitted', () => {
    buildWrapper();

    expect(findSavedChangesMessage().exists()).toBe(false);
  });

  describe('when content is loaded', () => {
    beforeEach(() => {
      buildStore({ initialState: { isSavingChanges: true } });
      buildWrapper({ sourceContent: { title, content } });
    });

    it('renders edit area', () => {
      expect(findEditArea().exists()).toBe(true);
    });

    it('provides source content to the edit area', () => {
      expect(findEditArea().props()).toMatchObject({
        title,
        content,
      });
    });

    it('provides returnUrl to the edit area', () => {
      expect(findEditArea().props('returnUrl')).toBe(returnUrl);
    });

    it('provides isSavingChanges to the edit area', () => {
      expect(findEditArea().props('savingChanges')).toBe(true);
    });
  });

  it('does not render edit area when content is not loaded', () => {
    buildWrapper({ sourceContent: null });

    expect(findEditArea().exists()).toBe(false);
  });

  it('renders skeleton loader when content is not loading', () => {
    buildApollo({
      sourceContent: {
        loading: true,
      },
    });
    buildWrapper();

    expect(findSkeletonLoader().exists()).toBe(true);
  });

  it('does not render skeleton loader when content is not loading', () => {
    buildApollo({
      sourceContent: {
        loading: false,
      },
    });
    buildWrapper();

    expect(findSkeletonLoader().exists()).toBe(false);
  });

  describe('when submitting changes fail', () => {
    beforeEach(() => {
      buildStore({
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

  it('does not display submit changes error when an error does not exist', () => {
    buildWrapper();

    expect(findSubmitChangesError().exists()).toBe(false);
  });

  it('displays invalid content message when content is not supported', () => {
    buildWrapper({ appData: { isSupportedContent: false } });

    expect(findInvalidContentMessage().exists()).toBe(true);
  });

  describe('when edit area emits submit event', () => {
    const newContent = `new ${content}`;

    beforeEach(() => {
      buildWrapper({ sourceContent: { title, content } });
      findEditArea().vm.$emit('submit', { content: newContent });
    });

    it('dispatches setContent property', () => {
      expect(setContentActionMock).toHaveBeenCalledWith(expect.anything(), newContent, undefined);
    });

    it('dispatches submitChanges action', () => {
      expect(submitChangesActionMock).toHaveBeenCalled();
    });
  });
});
