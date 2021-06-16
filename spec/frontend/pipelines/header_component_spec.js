import { GlModal, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import HeaderComponent from '~/pipelines/components/header_component.vue';
import cancelPipelineMutation from '~/pipelines/graphql/mutations/cancel_pipeline.mutation.graphql';
import deletePipelineMutation from '~/pipelines/graphql/mutations/delete_pipeline.mutation.graphql';
import retryPipelineMutation from '~/pipelines/graphql/mutations/retry_pipeline.mutation.graphql';
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

  const findDeleteModal = () => wrapper.find(GlModal);
  const findRetryButton = () => wrapper.find('[data-testid="retryPipeline"]');
  const findCancelButton = () => wrapper.find('[data-testid="cancelPipeline"]');
  const findDeleteButton = () => wrapper.find('[data-testid="deletePipeline"]');
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);

  const defaultProvideOptions = {
    pipelineId: 14,
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
      mutate: jest.fn(),
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

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

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

  describe('polling', () => {
    it('is stopped when pipeline is finished', async () => {
      wrapper = createComponent({ ...mockRunningPipelineHeader });

      await wrapper.setData({
        pipeline: { ...mockCancelledPipelineHeader },
      });

      expect(wrapper.vm.$apollo.queries.pipeline.stopPolling).toHaveBeenCalled();
    });

    it('is not stopped when pipeline is not finished', () => {
      wrapper = createComponent();

      expect(wrapper.vm.$apollo.queries.pipeline.stopPolling).not.toHaveBeenCalled();
    });
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
        findDeleteModal().vm.$emit('ok');

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
          mutation: deletePipelineMutation,
          variables: { id: mockFailedPipelineHeader.id },
        });
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
