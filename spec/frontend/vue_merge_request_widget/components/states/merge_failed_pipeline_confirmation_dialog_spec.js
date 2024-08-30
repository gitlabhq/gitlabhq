import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import { createAlert } from '~/alert';
import MergeFailedPipelineConfirmationDialog from '~/vue_merge_request_widget/components/states/merge_failed_pipeline_confirmation_dialog.vue';
import {
  HTTP_STATUS_UNAUTHORIZED,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
} from '~/lib/utils/http_status';
import { trimText } from 'helpers/text_helper';

jest.mock('~/alert');
jest.mock('~/api');

describe('MergeFailedPipelineConfirmationDialog', () => {
  const mockModalHide = jest.fn();

  let wrapper;

  const GlModal = {
    template: `
      <div>
        <slot></slot>
        <slot name="modal-footer"></slot>
      </div>
    `,
    methods: {
      hide: mockModalHide,
    },
  };

  const createComponent = () => {
    wrapper = shallowMount(MergeFailedPipelineConfirmationDialog, {
      propsData: {
        visible: true,
        targetProjectId: 1,
        iid: 1,
      },
      stubs: {
        GlModal,
      },
      attachTo: document.body,
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findMergeBtn = () => wrapper.find('[data-testid="merge-unverified-changes"]');
  const findCancelBtn = () => wrapper.find('[data-testid="merge-cancel-btn"]');
  const findRunPipelineButton = () => wrapper.find('[data-testid="run-pipeline-button"]');

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    mockModalHide.mockReset();
  });

  it('should render informational text explaining why merging immediately can be dangerous', () => {
    expect(trimText(wrapper.text())).toContain(
      'The merge checks are incomplete because the latest pipeline failed, the pipeline status cannot be verified, or the merge request target branch was changed. You should run a new pipeline before merging.',
    );
  });

  it('should emit the mergeWithFailedPipeline event', () => {
    findMergeBtn().vm.$emit('click');

    expect(wrapper.emitted('mergeWithFailedPipeline')).toHaveLength(1);
  });

  it('when the cancel button is clicked should emit cancel and call hide', () => {
    findCancelBtn().vm.$emit('click');

    expect(wrapper.emitted('cancel')).toHaveLength(1);
    expect(mockModalHide).toHaveBeenCalled();
  });

  it('should emit cancel when the hide event is emitted', () => {
    findModal().vm.$emit('hide');

    expect(wrapper.emitted('cancel')).toHaveLength(1);
  });

  it('when modal is shown it will focus the cancel button', () => {
    jest.spyOn(findCancelBtn().element, 'focus');

    findModal().vm.$emit('shown');

    expect(findCancelBtn().element.focus).toHaveBeenCalled();
  });

  it('calls postMergeRequestPipeline API method', async () => {
    findRunPipelineButton().vm.$emit('click');

    await nextTick();

    expect(findRunPipelineButton().props('loading')).toBe(true);
    expect(Api.postMergeRequestPipeline).toHaveBeenCalledWith(1, { mergeRequestId: 1 });
  });

  describe('when API call fails', () => {
    describe('when user has permission to create a pipeline', () => {
      beforeEach(() => {
        Api.postMergeRequestPipeline.mockRejectedValue({
          response: { status: HTTP_STATUS_INTERNAL_SERVER_ERROR },
        });
      });

      it('returns loading state on button to default state', async () => {
        findRunPipelineButton().vm.$emit('click');

        await waitForPromises();

        expect(findRunPipelineButton().props('loading')).toBe(false);
      });

      it('creates a new alert', async () => {
        findRunPipelineButton().vm.$emit('click');

        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred while trying to run a new pipeline for this merge request.',
          primaryButton: {
            link: '/help/ci/pipelines/merge_request_pipelines.md',
            text: 'Learn more',
          },
        });
      });
    });

    describe('when user does not have permission to create a pipeline', () => {
      beforeEach(() => {
        Api.postMergeRequestPipeline.mockRejectedValue({
          response: { status: HTTP_STATUS_UNAUTHORIZED },
        });
      });

      it('creates a new alert', async () => {
        findRunPipelineButton().vm.$emit('click');

        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'You do not have permission to run a pipeline on this branch.',
          primaryButton: {
            link: '/help/ci/pipelines/merge_request_pipelines.md',
            text: 'Learn more',
          },
        });
      });
    });
  });
});
