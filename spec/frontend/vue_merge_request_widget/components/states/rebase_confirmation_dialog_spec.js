import { shallowMount } from '@vue/test-utils';
import RebaseConfirmationDialog from '~/vue_merge_request_widget/components/states/rebase_confirmation_dialog.vue';
import { trimText } from 'helpers/text_helper';

describe('RebaseConfirmationDialog', () => {
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

  const createComponent = (props = {}) => {
    wrapper = shallowMount(RebaseConfirmationDialog, {
      propsData: {
        visible: true,
        ...props,
      },
      stubs: {
        GlModal,
      },
      attachTo: document.body,
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findRebaseBtn = () => wrapper.find('[data-testid="confirm-rebase"]');
  const findCancelBtn = () => wrapper.find('[data-testid="rebase-cancel-btn"]');

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    mockModalHide.mockReset();
  });

  it('renders rebase confirmation text', () => {
    expect(trimText(wrapper.text())).toContain(
      'This will rebase all commits from the source branch onto the target branch.',
    );
  });

  it('emits rebaseConfirmed when rebase button is clicked', () => {
    findRebaseBtn().vm.$emit('click');

    expect(wrapper.emitted('rebase-confirmed')).toHaveLength(1);
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
