import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelinesManualActions from '~/pipelines/components/pipelines_list/pipelines_manual_actions.vue';
import PipelinesManualActionsLegacy from '~/pipelines/components/pipelines_list/pipelines_manual_actions_legacy.vue';
import PipelineMultiActions from '~/pipelines/components/pipelines_list/pipeline_multi_actions.vue';
import PipelineOperations from '~/pipelines/components/pipelines_list/pipeline_operations.vue';
import eventHub from '~/pipelines/event_hub';

describe('Pipeline operations', () => {
  let wrapper;

  const defaultProps = {
    pipeline: {
      id: 329,
      iid: 234,
      details: {
        has_manual_actions: true,
        has_scheduled_actions: false,
        manual_actions: [
          {
            name: 'dont-interrupt-me',
            path: '/root/ci-project/-/jobs/3974323562/play',
            playable: true,
            scheduled: false,
          },
        ],
        scheduled_actions: [],
      },
      flags: {
        retryable: true,
        cancelable: true,
      },
      cancel_path: '/root/ci-project/-/pipelines/329/cancel',
      retry_path: '/root/ci-project/-/pipelines/329/retry',
    },
  };

  const createComponent = (props = defaultProps, flagState = true) => {
    wrapper = shallowMountExtended(PipelineOperations, {
      provide: {
        glFeatures: {
          lazyLoadPipelineDropdownActions: flagState,
        },
      },
      propsData: {
        ...props,
      },
    });
  };

  const findLegacyManualActions = () => wrapper.findComponent(PipelinesManualActionsLegacy);
  const findManualActions = () => wrapper.findComponent(PipelinesManualActions);
  const findMultiActions = () => wrapper.findComponent(PipelineMultiActions);
  const findRetryBtn = () => wrapper.findByTestId('pipelines-retry-button');
  const findCancelBtn = () => wrapper.findByTestId('pipelines-cancel-button');

  it('should display pipeline manual actions', () => {
    createComponent();

    expect(findManualActions().exists()).toBe(true);
    expect(findLegacyManualActions().exists()).toBe(false);
  });

  it('should display legacy pipeline manual actions', () => {
    createComponent(defaultProps, false);

    expect(findLegacyManualActions().exists()).toBe(true);
    expect(findManualActions().exists()).toBe(false);
  });

  it('should display pipeline multi actions', () => {
    createComponent();

    expect(findMultiActions().exists()).toBe(true);
  });

  describe('events', () => {
    beforeEach(() => {
      createComponent();

      jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
    });

    it('should emit retryPipeline event', () => {
      findRetryBtn().vm.$emit('click');

      expect(eventHub.$emit).toHaveBeenCalledWith(
        'retryPipeline',
        defaultProps.pipeline.retry_path,
      );
    });

    it('should emit openConfirmationModal event', () => {
      findCancelBtn().vm.$emit('click');

      expect(eventHub.$emit).toHaveBeenCalledWith('openConfirmationModal', {
        pipeline: defaultProps.pipeline,
        endpoint: defaultProps.pipeline.cancel_path,
      });
    });
  });
});
