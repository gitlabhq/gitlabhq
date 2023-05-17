import { shallowMount } from '@vue/test-utils';
import MergeFailedPipelineConfirmationDialog from '~/vue_merge_request_widget/components/states/merge_failed_pipeline_confirmation_dialog.vue';
import { trimText } from 'helpers/text_helper';

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

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    mockModalHide.mockReset();
  });

  it('should render informational text explaining why merging immediately can be dangerous', () => {
    expect(trimText(wrapper.text())).toContain(
      'The latest pipeline for this merge request did not succeed. The latest changes are unverified. Are you sure you want to attempt to merge?',
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
});
