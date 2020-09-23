import { shallowMount } from '@vue/test-utils';
import { GlModal, GlLoadingIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import {
  mockCancelledPipelineHeader,
  mockFailedPipelineHeader,
  mockRunningPipelineHeader,
  mockSuccessfulPipelineHeader,
} from './mock_data';
import axios from '~/lib/utils/axios_utils';
import HeaderComponent from '~/pipelines/components/header_component.vue';

describe('Pipeline details header', () => {
  let wrapper;
  let glModalDirective;
  let mockAxios;

  const findDeleteModal = () => wrapper.find(GlModal);
  const findRetryButton = () => wrapper.find('[data-testid="retryPipeline"]');
  const findCancelButton = () => wrapper.find('[data-testid="cancelPipeline"]');
  const findDeleteButton = () => wrapper.find('[data-testid="deletePipeline"]');
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);

  const defaultProvideOptions = {
    pipelineId: 14,
    pipelineIid: 1,
    paths: {
      retry: '/retry',
      cancel: '/cancel',
      delete: '/delete',
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

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    mockAxios.onGet('*').replyOnce(200);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;

    mockAxios.restore();
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

  describe('actions', () => {
    describe('Retry action', () => {
      beforeEach(() => {
        wrapper = createComponent(mockCancelledPipelineHeader);
      });

      it('should call axios with the right path when retry button is clicked', async () => {
        jest.spyOn(axios, 'post');
        findRetryButton().vm.$emit('click');

        await wrapper.vm.$nextTick();

        expect(axios.post).toHaveBeenCalledWith(defaultProvideOptions.paths.retry);
      });
    });

    describe('Cancel action', () => {
      beforeEach(() => {
        wrapper = createComponent(mockRunningPipelineHeader);
      });

      it('should call axios with the right path when cancel button is clicked', async () => {
        jest.spyOn(axios, 'post');
        findCancelButton().vm.$emit('click');

        await wrapper.vm.$nextTick();

        expect(axios.post).toHaveBeenCalledWith(defaultProvideOptions.paths.cancel);
      });
    });

    describe('Delete action', () => {
      beforeEach(() => {
        wrapper = createComponent(mockFailedPipelineHeader);
      });

      it('displays delete modal when clicking on delete and does not call the delete action', async () => {
        jest.spyOn(axios, 'delete');
        findDeleteButton().vm.$emit('click');

        await wrapper.vm.$nextTick();

        expect(findDeleteModal().props('modalId')).toBe(wrapper.vm.$options.DELETE_MODAL_ID);
        expect(glModalDirective).toHaveBeenCalledWith(wrapper.vm.$options.DELETE_MODAL_ID);
        expect(axios.delete).not.toHaveBeenCalled();
      });

      it('should call delete path when modal is submitted', async () => {
        jest.spyOn(axios, 'delete');
        findDeleteModal().vm.$emit('ok');

        await wrapper.vm.$nextTick();

        expect(axios.delete).toHaveBeenCalledWith(defaultProvideOptions.paths.delete);
      });
    });
  });
});
