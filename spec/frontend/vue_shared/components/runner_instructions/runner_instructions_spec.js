import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerInstructions from '~/vue_shared/components/runner_instructions/runner_instructions.vue';
import RunnerInstructionsModal from '~/vue_shared/components/runner_instructions/runner_instructions_modal.vue';

describe('RunnerInstructions component', () => {
  let wrapper;

  const findModalButton = () => wrapper.findByTestId('show-modal-button');
  const findModal = () => wrapper.findComponent(RunnerInstructionsModal);

  const createComponent = () => {
    wrapper = shallowMountExtended(RunnerInstructions, {
      directives: {
        GlModal: createMockDirective('gl-tooltip'),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('should show the "Show runner installation instructions" button', () => {
    expect(findModalButton().text()).toBe('Show runner installation instructions');
  });

  it('should render the modal', () => {
    const modalId = getBinding(findModal().element, 'gl-modal');

    expect(findModalButton().attributes('modal-id')).toBe(modalId);
  });
});
