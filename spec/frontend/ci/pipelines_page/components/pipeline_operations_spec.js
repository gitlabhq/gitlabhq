import { nextTick } from 'vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelinesManualActions from '~/ci/pipelines_page/components/pipelines_manual_actions.vue';
import PipelineMultiActions from '~/ci/pipelines_page/components/pipeline_multi_actions.vue';
import PipelineOperations from '~/ci/pipelines_page/components/pipeline_operations.vue';
import PipelineStopModal from '~/ci/pipelines_page/components/pipeline_stop_modal.vue';
import { TRACKING_CATEGORIES } from '~/ci/constants';

describe('Pipeline operations', () => {
  let trackingSpy;
  let wrapper;

  const defaultProps = {
    pipeline: {
      id: 329,
      iid: 234,
      project: {
        full_path: 'root/ci-project',
      },
      details: {
        has_manual_actions: true,
        has_scheduled_actions: false,
      },
      flags: {
        retryable: true,
        cancelable: true,
      },
      cancel_path: '/root/ci-project/-/pipelines/329/cancel',
      retry_path: '/root/ci-project/-/pipelines/329/retry',
    },
  };
  const createComponent = (props = defaultProps) => {
    wrapper = shallowMountExtended(PipelineOperations, {
      propsData: {
        ...props,
      },
    });
  };

  const findManualActions = () => wrapper.findComponent(PipelinesManualActions);
  const findMultiActions = () => wrapper.findComponent(PipelineMultiActions);
  const findRetryBtn = () => wrapper.findComponentByTestId('pipelines-retry-button');
  const findCancelBtn = () => wrapper.findComponentByTestId('pipelines-cancel-button');
  const findPipelineStopModal = () => wrapper.findComponent(PipelineStopModal);

  const graphqlProps = {
    pipeline: {
      id: 'gid://gitlab/Ci::Pipeline/329',
      iid: '234',
      project: {
        fullPath: 'root/ci-project',
      },
      hasManualActions: true,
      hasScheduledActions: false,
      retryable: true,
      cancelable: true,
      userPermissions: {
        cancelPipeline: true,
        updatePipeline: true,
      },
    },
  };

  it('should display pipeline manual actions', () => {
    createComponent();

    expect(findManualActions().exists()).toBe(true);
  });

  it('should display pipeline multi actions', () => {
    createComponent();

    expect(findMultiActions().exists()).toBe(true);
  });

  it('does not show the confirmation modal', () => {
    createComponent();

    expect(findPipelineStopModal().props().showConfirmationModal).toBe(false);
  });

  describe('with a REST pipeline', () => {
    it('shows the retry and cancel buttons based on flags alone', () => {
      createComponent();

      expect(findRetryBtn().exists()).toBe(true);
      expect(findCancelBtn().exists()).toBe(true);
    });
  });

  describe('with a GraphQL pipeline', () => {
    it.each`
      button      | findButton       | state                    | permissions                                        | exists
      ${'retry'}  | ${findRetryBtn}  | ${{ retryable: true }}   | ${{ cancelPipeline: true, updatePipeline: true }}  | ${true}
      ${'retry'}  | ${findRetryBtn}  | ${{ retryable: true }}   | ${{ cancelPipeline: true, updatePipeline: false }} | ${false}
      ${'retry'}  | ${findRetryBtn}  | ${{ retryable: false }}  | ${{ cancelPipeline: true, updatePipeline: true }}  | ${false}
      ${'cancel'} | ${findCancelBtn} | ${{ cancelable: true }}  | ${{ cancelPipeline: true, updatePipeline: true }}  | ${true}
      ${'cancel'} | ${findCancelBtn} | ${{ cancelable: true }}  | ${{ cancelPipeline: false, updatePipeline: true }} | ${false}
      ${'cancel'} | ${findCancelBtn} | ${{ cancelable: false }} | ${{ cancelPipeline: true, updatePipeline: true }}  | ${false}
    `(
      '$button button exists is $exists when state is $state and permissions are $permissions',
      ({ findButton, state, permissions, exists }) => {
        createComponent({
          pipeline: {
            ...graphqlProps.pipeline,
            ...state,
            userPermissions: permissions,
          },
        });

        expect(findButton().exists()).toBe(exists);
      },
    );

    it('does not show the retry and cancel buttons when userPermissions is missing', () => {
      createComponent({
        pipeline: {
          ...graphqlProps.pipeline,
          userPermissions: null,
        },
      });

      expect(findRetryBtn().exists()).toBe(false);
      expect(findCancelBtn().exists()).toBe(false);
    });
  });

  describe('when cancelling a pipeline', () => {
    beforeEach(async () => {
      createComponent();
      await findCancelBtn().vm.$emit('click');
    });

    it('should show a confirmation modal', () => {
      expect(findPipelineStopModal().props().showConfirmationModal).toBe(true);
    });

    it('should emit cancel-pipeline event when confirming', async () => {
      await findPipelineStopModal().vm.$emit('submit');

      expect(wrapper.emitted('cancel-pipeline')).toEqual([[defaultProps.pipeline]]);
      expect(findPipelineStopModal().props().showConfirmationModal).toBe(false);
    });

    it('should hide the modal when closing', async () => {
      await findPipelineStopModal().vm.$emit('close-modal');

      expect(findPipelineStopModal().props().showConfirmationModal).toBe(false);
    });
  });

  describe('events', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should emit retryPipeline event', () => {
      findRetryBtn().vm.$emit('click');

      expect(wrapper.emitted('retry-pipeline')).toEqual([[defaultProps.pipeline]]);
    });
  });

  describe('tracking', () => {
    beforeEach(() => {
      createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    it('tracks retry pipeline button click', () => {
      findRetryBtn().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_retry_button', {
        label: TRACKING_CATEGORIES.table,
      });
    });

    it('tracks cancel pipeline button click', () => {
      findCancelBtn().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_cancel_button', {
        label: TRACKING_CATEGORIES.table,
      });
    });
  });

  describe('button tooltips', () => {
    beforeEach(() => {
      createComponent();
    });

    it('cancel and retry buttons contain a key', async () => {
      findRetryBtn().vm.$emit('click');

      await nextTick();

      // forces Vue to completely destroy and recreate the button element
      // to avoid tooltip staleness with quick state changes
      expect(findRetryBtn().vm.$vnode.key).toBe('retry-true');
      expect(findCancelBtn().vm.$vnode.key).toBe('cancel-false');
    });
  });
});
