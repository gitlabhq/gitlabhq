import { GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import HeaderActions from '~/ci/pipeline_details/header/components/header_actions.vue';
import { BUTTON_TOOLTIP_RETRY, BUTTON_TOOLTIP_CANCEL, BUTTON_TOOLTIP_DELETE } from '~/ci/constants';
import {
  pipelineHeaderRunning,
  pipelineHeaderRunningNoPermissions,
  pipelineHeaderFailed,
  pipelineHeaderFailedNoPermissions,
} from '../../mock_data';

describe('Header actions', () => {
  let wrapper;
  let glModalDirective;

  const findModal = () => wrapper.findComponent(GlModal);
  const findRetryButton = () => wrapper.findByTestId('retry-pipeline');
  const findCancelButton = () => wrapper.findByTestId('cancel-pipeline');
  const findDeleteButton = () => wrapper.findByTestId('delete-pipeline');

  const defaultProps = {
    isRetrying: false,
    isCanceling: false,
    isDeleting: false,
  };

  const createComponent = (props) => {
    glModalDirective = jest.fn();

    wrapper = shallowMountExtended(HeaderActions, {
      propsData: {
        ...props,
        ...defaultProps,
      },
      directives: {
        glModal: {
          bind(_, { value }) {
            glModalDirective(value);
          },
        },
      },
    });
  };

  describe('confirmation modal', () => {
    it('should display modal when delete button is clicked', () => {
      createComponent({ pipeline: pipelineHeaderFailed.data.project.pipeline });

      findDeleteButton().vm.$emit('click');

      expect(findModal().props('modalId')).toBe('pipeline-delete-modal');
      expect(glModalDirective).toHaveBeenCalledWith('pipeline-delete-modal');
    });
  });

  describe('events', () => {
    it('emits the cancelPipeline event', () => {
      createComponent({ pipeline: pipelineHeaderRunning.data.project.pipeline });

      findCancelButton().vm.$emit('click');

      expect(wrapper.emitted()).toEqual({
        cancelPipeline: [[pipelineHeaderRunning.data.project.pipeline.id]],
      });
    });

    it('emits the deletePipeline event', () => {
      createComponent({ pipeline: pipelineHeaderFailed.data.project.pipeline });

      findModal().vm.$emit('primary');

      expect(wrapper.emitted()).toEqual({
        deletePipeline: [[pipelineHeaderFailed.data.project.pipeline.id]],
      });
    });

    it('emits the retryPipeline event', () => {
      createComponent({ pipeline: pipelineHeaderFailed.data.project.pipeline });

      findRetryButton().vm.$emit('click');

      expect(wrapper.emitted()).toEqual({
        retryPipeline: [[pipelineHeaderFailed.data.project.pipeline.id]],
      });
    });
  });

  describe('tooltips', () => {
    it('displays retry and delete tooltip', () => {
      createComponent({ pipeline: pipelineHeaderFailed.data.project.pipeline });

      expect(findRetryButton().attributes('title')).toBe(BUTTON_TOOLTIP_RETRY);
      expect(findDeleteButton().attributes('title')).toBe(BUTTON_TOOLTIP_DELETE);
    });

    it('displays cancel tooltip', () => {
      createComponent({ pipeline: pipelineHeaderRunning.data.project.pipeline });

      expect(findCancelButton().attributes('title')).toBe(BUTTON_TOOLTIP_CANCEL);
    });
  });

  describe('permissions', () => {
    it('cancel button is not visible', () => {
      createComponent({ pipeline: pipelineHeaderRunningNoPermissions.data.project.pipeline });

      expect(findCancelButton().exists()).toBe(false);
    });

    it('retry button and delete button are not visible', () => {
      createComponent({ pipeline: pipelineHeaderFailedNoPermissions.data.project.pipeline });

      expect(findRetryButton().exists()).toBe(false);
      expect(findDeleteButton().exists()).toBe(false);
    });
  });
});
