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
  const findRetryBtn = () => wrapper.findByTestId('pipelines-retry-button');
  const findCancelBtn = () => wrapper.findByTestId('pipelines-cancel-button');
  const findPipelineStopModal = () => wrapper.findComponent(PipelineStopModal);

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
});
