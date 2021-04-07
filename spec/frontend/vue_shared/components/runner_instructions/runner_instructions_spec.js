import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import RunnerInstructions from '~/vue_shared/components/runner_instructions/runner_instructions.vue';
import RunnerInstructionsModal from '~/vue_shared/components/runner_instructions/runner_instructions_modal.vue';

describe('RunnerInstructions component', () => {
  let wrapper;

  const findModalButton = () => wrapper.findByTestId('show-modal-button');
  const findModal = () => wrapper.findComponent(RunnerInstructionsModal);

  const createComponent = () => {
    wrapper = extendedWrapper(shallowMount(RunnerInstructions));
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should show the "Show Runner installation instructions" button', () => {
    expect(findModalButton().exists()).toBe(true);
    expect(findModalButton().text()).toBe('Show Runner installation instructions');
  });

  it('should not render the modal once mounted', () => {
    expect(findModal().exists()).toBe(false);
  });

  it('should render the modal once clicked', async () => {
    findModalButton().vm.$emit('click');

    await nextTick();

    expect(findModal().exists()).toBe(true);
  });
});
