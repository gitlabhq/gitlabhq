import { shallowMount, createLocalVue } from '@vue/test-utils';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import EditArea from '~/static_site_editor/components/edit_area.vue';
import EditMetaModal from '~/static_site_editor/components/edit_meta_modal.vue';
import InvalidContentMessage from '~/static_site_editor/components/invalid_content_message.vue';
import SkeletonLoader from '~/static_site_editor/components/skeleton_loader.vue';
import SubmitChangesError from '~/static_site_editor/components/submit_changes_error.vue';
import { TRACKING_ACTION_INITIALIZE_EDITOR } from '~/static_site_editor/constants';
import hasSubmittedChangesMutation from '~/static_site_editor/graphql/mutations/has_submitted_changes.mutation.graphql';
import submitContentChangesMutation from '~/static_site_editor/graphql/mutations/submit_content_changes.mutation.graphql';
import Home from '~/static_site_editor/pages/home.vue';
import { SUCCESS_ROUTE } from '~/static_site_editor/router/constants';

import {
  project,
  returnUrl,
  sourceContentYAML as content,
  sourceContentTitle as title,
  sourcePath,
  username,
  mergeRequestMeta,
  savedContentMeta,
  submitChangesError,
  trackingCategory,
  images,
  mounts,
  branch,
  baseUrl,
  imageRoot,
} from '../mock_data';

const localVue = createLocalVue();

describe('static_site_editor/pages/home', () => {
  let wrapper;
  let store;
  let $apollo;
  let $router;
  let mutateMock;
  let trackingSpy;
  const defaultAppData = {
    isSupportedContent: true,
    hasSubmittedChanges: false,
    returnUrl,
    project,
    username,
    sourcePath,
    mounts,
    branch,
    baseUrl,
    imageUploadPath: imageRoot,
  };
  const hasSubmittedChangesMutationPayload = {
    data: {
      appData: { ...defaultAppData, hasSubmittedChanges: true },
    },
  };

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
          appData: { ...defaultAppData },
          sourceContent: { title, content },
          ...data,
        };
      },
    });
  };

  const findEditArea = () => wrapper.find(EditArea);
  const findEditMetaModal = () => wrapper.find(EditMetaModal);
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
        mounts,
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
    buildWrapper({ appData: { ...defaultAppData, isSupportedContent: false } });

    expect(findInvalidContentMessage().exists()).toBe(true);
  });

  it('does not display invalid content message when content is supported', () => {
    buildWrapper();

    expect(findInvalidContentMessage().exists()).toBe(false);
  });

  it('renders an EditMetaModal component', () => {
    buildWrapper();

    expect(findEditMetaModal().exists()).toBe(true);
  });

  describe('when preparing submission', () => {
    it('calls the show method when the edit-area submit event is emitted', () => {
      buildWrapper();

      const mockInstance = { show: jest.fn() };
      wrapper.vm.$refs.editMetaModal = mockInstance;

      findEditArea().vm.$emit('submit', { content });

      return wrapper.vm.$nextTick().then(() => {
        expect(mockInstance.show).toHaveBeenCalled();
      });
    });
  });

  describe('when submitting changes fails', () => {
    const setupMutateMock = () => {
      mutateMock
        .mockResolvedValueOnce(hasSubmittedChangesMutationPayload)
        .mockRejectedValueOnce(new Error(submitChangesError));
    };

    beforeEach(() => {
      setupMutateMock();

      buildWrapper({ content });
      findEditMetaModal().vm.$emit('primary', mergeRequestMeta);

      return wrapper.vm.$nextTick();
    });

    it('displays submit changes error message', () => {
      expect(findSubmitChangesError().exists()).toBe(true);
    });

    it('retries submitting changes when retry button is clicked', () => {
      setupMutateMock();

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

  describe('when submitting changes succeeds', () => {
    const newContent = `new ${content}`;
    const formattedMarkdown = `formatted ${content}`;

    beforeEach(() => {
      mutateMock.mockResolvedValueOnce(hasSubmittedChangesMutationPayload).mockResolvedValueOnce({
        data: {
          submitContentChanges: savedContentMeta,
        },
      });

      buildWrapper();

      findEditMetaModal().vm.show = jest.fn();

      findEditArea().vm.$emit('submit', { content: newContent, images, formattedMarkdown });

      findEditMetaModal().vm.$emit('primary', mergeRequestMeta);

      return wrapper.vm.$nextTick();
    });

    it('dispatches hasSubmittedChanges mutation', () => {
      expect(mutateMock).toHaveBeenNthCalledWith(1, {
        mutation: hasSubmittedChangesMutation,
        variables: {
          input: {
            hasSubmittedChanges: true,
          },
        },
      });
    });

    it('dispatches submitContentChanges mutation', () => {
      expect(mutateMock).toHaveBeenNthCalledWith(2, {
        mutation: submitContentChangesMutation,
        variables: {
          input: {
            content: newContent,
            formattedMarkdown,
            project,
            sourcePath,
            targetBranch: branch,
            username,
            images,
            mergeRequestMeta,
          },
        },
      });
    });

    it('transitions to the SUCCESS route', () => {
      expect($router.push).toHaveBeenCalledWith(SUCCESS_ROUTE);
    });
  });

  it('does not display submit changes error when an error does not exist', () => {
    buildWrapper();

    expect(findSubmitChangesError().exists()).toBe(false);
  });

  it('tracks when editor is initialized on the mounted lifecycle hook', () => {
    buildWrapper();
    expect(trackingSpy).toHaveBeenCalledWith(
      document.body.dataset.page,
      TRACKING_ACTION_INITIALIZE_EDITOR,
    );
  });
});
