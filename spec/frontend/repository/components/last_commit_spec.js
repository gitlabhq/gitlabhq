import Vue from 'vue';
import { GlLoadingIcon } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LastCommit from '~/repository/components/last_commit.vue';
import CommitInfo from '~/repository/components/commit_info.vue';
import SignatureBadge from '~/commit/components/signature_badge.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import eventHub from '~/repository/event_hub';
import pathLastCommitQuery from 'shared_queries/repository/path_last_commit.query.graphql';
import pipelineCiStatusUpdatedSubscription from '~/graphql_shared/subscriptions/pipeline_ci_status_updated.subscription.graphql';
import { FORK_UPDATED_EVENT } from '~/repository/constants';
import { mockPipelineStatusUpdatedResponse, createCommitData } from '../mock_data';

Vue.use(VueApollo);

const { bindInternalEventDocument } = useMockInternalEventsTracking();

describe('Repository last commit component', () => {
  let wrapper;
  let commitData;
  let mockResolver;
  let apolloProvider;

  const findLastCommitLabel = () => wrapper.findByTestId('last-commit-id-label');
  const findHistoryButton = () => wrapper.findByTestId('last-commit-history');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findStatusBox = () => wrapper.findComponent(SignatureBadge);
  const findCommitInfo = () => wrapper.findComponent(CommitInfo);
  const findPipelineStatus = () => wrapper.findComponent(CiIcon);

  const subscriptionHandler = jest.fn().mockResolvedValue(mockPipelineStatusUpdatedResponse);

  const createComponent = (data = {}, pipelineSubscriptionHandler = subscriptionHandler) => {
    const currentPath = 'path';

    commitData = createCommitData(data);
    mockResolver = jest.fn().mockResolvedValue(commitData);

    apolloProvider = createMockApollo([
      [pathLastCommitQuery, mockResolver],
      [pipelineCiStatusUpdatedSubscription, pipelineSubscriptionHandler],
    ]);

    wrapper = shallowMountExtended(LastCommit, {
      apolloProvider,
      propsData: { currentPath, historyUrl: '/history' },
      provide: {
        glFeatures: {
          ciPipelineStatusRealtime: true,
        },
      },
    });
  };

  it.each`
    loading  | label
    ${true}  | ${'shows'}
    ${false} | ${'hides'}
  `('$label when loading icon is $loading', async ({ loading }) => {
    createComponent();

    if (!loading) {
      await waitForPromises();
    }

    expect(findLoadingIcon().exists()).toBe(loading);
  });

  it('renders a CommitInfo component', async () => {
    createComponent();

    await waitForPromises();

    const commit = { ...commitData.project?.repository.paginatedTree.nodes[0].lastCommit };

    expect(findCommitInfo().props().commit).toMatchObject(commit);
  });

  it('renders commit widget', async () => {
    createComponent();

    await waitForPromises();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders short commit ID', async () => {
    createComponent();

    await waitForPromises();

    expect(findLastCommitLabel().text()).toBe('12345678');
  });

  describe('history button', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('renders History button with correct href', () => {
      expect(findHistoryButton().attributes('href')).toContain('/history');
    });

    it('should call trackEvent method when clicked on history button', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      findHistoryButton().vm.$emit('click');
      expect(trackEventSpy).toHaveBeenCalledWith(
        'click_history_control_on_blob_page',
        {},
        undefined,
      );
    });
  });

  it('hides pipeline components when pipeline does not exist', async () => {
    createComponent({ pipelineEdges: [] });

    await waitForPromises();

    expect(findPipelineStatus().exists()).toBe(false);
  });

  it('renders pipeline components when pipeline exists', async () => {
    createComponent();

    await waitForPromises();

    expect(findPipelineStatus().exists()).toBe(true);
  });

  describe('created', () => {
    it('binds `epicsListScrolled` event listener via eventHub', () => {
      jest.spyOn(eventHub, '$on').mockImplementation(() => {});

      createComponent();

      expect(eventHub.$on).toHaveBeenCalledWith(FORK_UPDATED_EVENT, expect.any(Function));
    });
  });

  describe('beforeDestroy', () => {
    it('unbinds `epicsListScrolled` event listener via eventHub', () => {
      jest.spyOn(eventHub, '$off').mockImplementation(() => {});

      createComponent();

      wrapper.destroy();

      expect(eventHub.$off).toHaveBeenCalledWith(FORK_UPDATED_EVENT, expect.any(Function));
    });
  });

  it('renders the signature HTML as returned by the backend', async () => {
    const signatureResponse = {
      __typename: 'GpgSignature',
      gpgKeyPrimaryKeyid: 'xxx',
      verificationStatus: 'VERIFIED',
    };

    createComponent({
      signature: {
        ...signatureResponse,
      },
    });

    await waitForPromises();

    expect(findStatusBox().props()).toMatchObject({ signature: signatureResponse });
  });

  describe('subscription', () => {
    it('calls subscription with correct variables', async () => {
      createComponent();

      await waitForPromises();

      expect(subscriptionHandler).toHaveBeenCalledWith({
        pipelineId: 'gid://gitlab/Ci::Pipeline/167',
      });
    });
  });

  describe('polling', () => {
    it('polls for last commit and pipeline data', () => {
      createComponent();

      expect(LastCommit.apollo.commit.pollInterval).toBe(30000);
    });
  });
});
