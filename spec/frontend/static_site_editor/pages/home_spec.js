import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Home from '~/static_site_editor/pages/home.vue';
import SkeletonLoader from '~/static_site_editor/components/skeleton_loader.vue';
import EditArea from '~/static_site_editor/components/edit_area.vue';
import InvalidContentMessage from '~/static_site_editor/components/invalid_content_message.vue';
import SubmitChangesError from '~/static_site_editor/components/submit_changes_error.vue';
import submitContentChangesMutation from '~/static_site_editor/graphql/mutations/submit_content_changes.mutation.graphql';
import { SUCCESS_ROUTE } from '~/static_site_editor/router/constants';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { TRACKING_ACTION_INITIALIZE_EDITOR } from '~/static_site_editor/constants';

import {
  projectId as project,
  returnUrl,
  sourceContent as content,
  sourceContentTitle as title,
  sourcePath,
  username,
  savedContentMeta,
  submitChangesError,
  trackingCategory,
} from '../mock_data';

const localVue = createLocalVue();

localVue.use(Vuex);

describe('static_site_editor/pages/home', () => {
  let wrapper;
  let store;
  let $apollo;
  let $router;
  let mutateMock;
  let trackingSpy;

  const buildApollo = (queries = {}) => {
    mutateMock = jest.fn();

    $apollo = {
      queries: {
        sourceContent: {
          loading: false,
        },
        ...queries,
      },
      mutate: mutateMock,
    };
  };

  const buildRouter = () => {
    $router = {
      push: jest.fn(),
    };
  };

  const buildWrapper = (data = {}) => {
    wrapper = shallowMount(Home, {
      localVue,
      store,
      mocks: {
        $apollo,
        $router,
      },
      data() {
        return {
          appData: { isSupportedContent: true, returnUrl, project, username, sourcePath },
          sourceContent: { title, content },
          ...data,
        };
      },
    });
  };

  const findEditArea = () => wrapper.find(EditArea);
  const findInvalidContentMessage = () => wrapper.find(InvalidContentMessage);
  const findSkeletonLoader = () => wrapper.find(SkeletonLoader);
  const findSubmitChangesError = () => wrapper.find(SubmitChangesError);

  beforeEach(() => {
    buildApollo();
    buildRouter();

    document.body.dataset.page = trackingCategory;
    trackingSpy = mockTracking(document.body.dataset.page, undefined, jest.spyOn);
  });

  afterEach(() => {
    wrapper.destroy();
    unmockTracking();
    wrapper = null;
    $apollo = null;
  });

  describe('when content is loaded', () => {
    beforeEach(() => {
      buildWrapper();
    });

    it('renders edit area', () => {
      expect(findEditArea().exists()).toBe(true);
    });

    it('provides source content, returnUrl, and isSavingChanges to the edit area', () => {
      expect(findEditArea().props()).toMatchObject({
        title,
        content,
        returnUrl,
        savingChanges: false,
      });
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

  it('displays invalid content message when content is not supported', () => {
    buildWrapper({ appData: { isSupportedContent: false } });

    expect(findInvalidContentMessage().exists()).toBe(true);
  });

  it('does not display invalid content message when content is supported', () => {
    buildWrapper({ appData: { isSupportedContent: true } });

    expect(findInvalidContentMessage().exists()).toBe(false);
  });

  describe('when submitting changes fails', () => {
    beforeEach(() => {
      mutateMock.mockRejectedValue(new Error(submitChangesError));

      buildWrapper();
      findEditArea().vm.$emit('submit', { content });

      return wrapper.vm.$nextTick();
    });

    it('displays submit changes error message', () => {
      expect(findSubmitChangesError().exists()).toBe(true);
    });

    it('retries submitting changes when retry button is clicked', () => {
      findSubmitChangesError().vm.$emit('retry');

      expect(mutateMock).toHaveBeenCalled();
    });

    it('hides submit changes error message when dismiss button is clicked', () => {
      findSubmitChangesError().vm.$emit('dismiss');

      return wrapper.vm.$nextTick().then(() => {
        expect(findSubmitChangesError().exists()).toBe(false);
      });
    });
  });

  it('does not display submit changes error when an error does not exist', () => {
    buildWrapper();

    expect(findSubmitChangesError().exists()).toBe(false);
  });

  describe('when submitting changes succeeds', () => {
    const newContent = `new ${content}`;

    beforeEach(() => {
      mutateMock.mockResolvedValueOnce({ data: { submitContentChanges: savedContentMeta } });

      buildWrapper();
      findEditArea().vm.$emit('submit', { content: newContent });

      return wrapper.vm.$nextTick();
    });

    it('dispatches submitContentChanges mutation', () => {
      expect(mutateMock).toHaveBeenCalledWith({
        mutation: submitContentChangesMutation,
        variables: {
          input: {
            content: newContent,
            project,
            sourcePath,
            username,
          },
        },
      });
    });

    it('transitions to the SUCCESS route', () => {
      expect($router.push).toHaveBeenCalledWith(SUCCESS_ROUTE);
    });
  });

  it('tracks when editor is initialized on the mounted lifecycle hook', () => {
    buildWrapper();
    expect(trackingSpy).toHaveBeenCalledWith(
      document.body.dataset.page,
      TRACKING_ACTION_INITIALIZE_EDITOR,
    );
  });
});
