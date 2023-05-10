import { GlAlert, GlModal, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import HeaderComponent from '~/pipelines/components/header_component.vue';
import cancelPipelineMutation from '~/pipelines/graphql/mutations/cancel_pipeline.mutation.graphql';
import deletePipelineMutation from '~/pipelines/graphql/mutations/delete_pipeline.mutation.graphql';
import retryPipelineMutation from '~/pipelines/graphql/mutations/retry_pipeline.mutation.graphql';
import { BUTTON_TOOLTIP_RETRY, BUTTON_TOOLTIP_CANCEL } from '~/pipelines/constants';
import {
  mockCancelledPipelineHeader,
  mockFailedPipelineHeader,
  mockFailedPipelineNoPermissions,
  mockRunningPipelineHeader,
  mockRunningPipelineNoPermissions,
  mockSuccessfulPipelineHeader,
} from './mock_data';

describe('Pipeline details header', () => {
  let wrapper;
  let glModalDirective;
  let mutate = jest.fn();

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findDeleteModal = () => wrapper.findComponent(GlModal);
  const findRetryButton = () => wrapper.find('[data-testid="retryPipeline"]');
  const findCancelButton = () => wrapper.find('[data-testid="cancelPipeline"]');
  const findDeleteButton = () => wrapper.find('[data-testid="deletePipeline"]');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const defaultProvideOptions = {
    pipelineId: '14',
    pipelineIid: 1,
    paths: {
      pipelinesPath: '/namespace/my-project/-/pipelines',
      fullProject: '/namespace/my-project',
    },
  };

  const createComponent = (pipelineMock = mockRunningPipelineHeader, { isLoading } = false) => {
    glModalDirective = jest.fn();

    const $apollo = {
      queries: {
        pipeline: {
          loading: isLoading,
          stopPolling: jest.fn(),
          startPolling: jest.fn(),
        },
      },
      mutate,
    };

    return shallowMount(HeaderComponent, {
      data() {
        return {
          pipeline: pipelineMock,
        };
      },
      provide: {
        ...defaultProvideOptions,
      },
      directives: {
        glModal: {
          bind(_, { value }) {
            glModalDirective(value);
          },
        },
      },
      mocks: { $apollo },
    });
  };

  describe('initial loading', () => {
    beforeEach(() => {
      wrapper = createComponent(null, { isLoading: true });
    });

    it('shows a loading state while graphQL is fetching initial data', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('visible state', () => {
    it.each`
      state           | pipelineData                    | retryValue | cancelValue
      ${'cancelled'}  | ${mockCancelledPipelineHeader}  | ${true}    | ${false}
      ${'failed'}     | ${mockFailedPipelineHeader}     | ${true}    | ${false}
      ${'running'}    | ${mockRunningPipelineHeader}    | ${false}   | ${true}
      ${'successful'} | ${mockSuccessfulPipelineHeader} | ${false}   | ${false}
    `(
      'with a $state pipeline, it will show actions: retry $retryValue and cancel $cancelValue',
      ({ pipelineData, retryValue, cancelValue }) => {
        wrapper = createComponent(pipelineData);

        expect(findRetryButton().exists()).toBe(retryValue);
        expect(findCancelButton().exists()).toBe(cancelValue);
      },
    );
  });

  describe('actions', () => {
    describe('Retry action', () => {
      beforeEach(() => {
        wrapper = createComponent(mockCancelledPipelineHeader);
      });

      it('should call retryPipeline Mutation with pipeline id', () => {
        findRetryButton().vm.$emit('click');

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
          mutation: retryPipelineMutation,
          variables: { id: mockCancelledPipelineHeader.id },
        });
      });

      it('should render retry action tooltip', () => {
        expect(findRetryButton().attributes('title')).toBe(BUTTON_TOOLTIP_RETRY);
      });

      it('should display error message on failure', async () => {
        const failureMessage = 'failure message';
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({
          data: {
            pipelineRetry: {
              errors: [failureMessage],
            },
          },
        });

        findRetryButton().vm.$emit('click');
        await waitForPromises();

        expect(findAlert().text()).toBe(failureMessage);
      });
    });

    describe('Retry action failed', () => {
      beforeEach(() => {
        mutate = jest.fn().mockRejectedValue('error');

        wrapper = createComponent(mockCancelledPipelineHeader);
      });

      it('retry button loading state should reset on error', async () => {
        findRetryButton().vm.$emit('click');

        await nextTick();

        expect(findRetryButton().props('loading')).toBe(true);

        await waitForPromises();

        expect(findRetryButton().props('loading')).toBe(false);
      });
    });

    describe('Cancel action', () => {
      beforeEach(() => {
        wrapper = createComponent(mockRunningPipelineHeader);
      });

      it('should call cancelPipeline Mutation with pipeline id', () => {
        findCancelButton().vm.$emit('click');

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
          mutation: cancelPipelineMutation,
          variables: { id: mockRunningPipelineHeader.id },
        });
      });

      it('should render cancel action tooltip', () => {
        expect(findCancelButton().attributes('title')).toBe(BUTTON_TOOLTIP_CANCEL);
      });

      it('should display error message on failure', async () => {
        const failureMessage = 'failure message';
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({
          data: {
            pipelineCancel: {
              errors: [failureMessage],
            },
          },
        });

        findCancelButton().vm.$emit('click');
        await waitForPromises();

        expect(findAlert().text()).toBe(failureMessage);
      });
    });

    describe('Delete action', () => {
      beforeEach(() => {
        wrapper = createComponent(mockFailedPipelineHeader);
      });

      it('displays delete modal when clicking on delete and does not call the delete action', () => {
        findDeleteButton().vm.$emit('click');

        expect(findDeleteModal().props('modalId')).toBe(wrapper.vm.$options.DELETE_MODAL_ID);
        expect(glModalDirective).toHaveBeenCalledWith(wrapper.vm.$options.DELETE_MODAL_ID);
        expect(wrapper.vm.$apollo.mutate).not.toHaveBeenCalled();
      });

      it('should call deletePipeline Mutation with pipeline id when modal is submitted', () => {
        findDeleteModal().vm.$emit('primary');

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
          mutation: deletePipelineMutation,
          variables: { id: mockFailedPipelineHeader.id },
        });
      });

      it('should display error message on failure', async () => {
        const failureMessage = 'failure message';
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({
          data: {
            pipelineDestroy: {
              errors: [failureMessage],
            },
          },
        });

        findDeleteModal().vm.$emit('primary');
        await waitForPromises();

        expect(findAlert().text()).toBe(failureMessage);
      });
    });

    describe('Permissions', () => {
      it('should not display the cancel action if user does not have permission', () => {
        wrapper = createComponent(mockRunningPipelineNoPermissions);

        expect(findCancelButton().exists()).toBe(false);
      });

      it('should not display the retry action if user does not have permission', () => {
        wrapper = createComponent(mockFailedPipelineNoPermissions);

        expect(findRetryButton().exists()).toBe(false);
      });
    });
  });
});
