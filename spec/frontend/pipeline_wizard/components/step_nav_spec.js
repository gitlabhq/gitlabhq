import { mountExtended } from 'helpers/vue_test_utils_helper';
import StepNav from '~/pipeline_wizard/components/step_nav.vue';

describe('Pipeline Wizard - Step Navigation Component', () => {
  const defaultProps = { showBackButton: true, showNextButton: true };

  let wrapper;
  let prevButton;
  let nextButton;

  const createComponent = (props = {}) => {
    wrapper = mountExtended(StepNav, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
    prevButton = wrapper.findByTestId('back-button');
    nextButton = wrapper.findByTestId('next-button');
  };

  it.each`
    scenario                       | showBackButton | showNextButton
    ${'does not show prev button'} | ${false}       | ${false}
    ${'has prev, but not next'}    | ${true}        | ${false}
    ${'has next, but not prev'}    | ${false}       | ${true}
    ${'has both next and prev'}    | ${true}        | ${true}
  `('$scenario', ({ showBackButton, showNextButton }) => {
    createComponent({ showBackButton, showNextButton });

    expect(prevButton.exists()).toBe(showBackButton);
    expect(nextButton.exists()).toBe(showNextButton);
  });

  it('shows the expected button text', () => {
    createComponent();

    expect(prevButton.text()).toBe('Back');
    expect(nextButton.text()).toBe('Next');
  });

  it('emits "back" events when clicking prev button', async () => {
    createComponent();

    await prevButton.trigger('click');
    expect(wrapper.emitted().back.length).toBe(1);
  });

  it('emits "next" events when clicking next button', async () => {
    createComponent();

    await nextButton.trigger('click');
    expect(wrapper.emitted().next.length).toBe(1);
  });

  it('enables the next button if nextButtonEnabled ist set to true', () => {
    createComponent({ nextButtonEnabled: true });

    expect(nextButton.attributes('disabled')).toBeUndefined();
  });

  it('disables the next button if nextButtonEnabled ist set to false', () => {
    createComponent({ nextButtonEnabled: false });

    expect(nextButton.attributes('disabled')).toBeDefined();
  });

  it('does not emit "next" event when clicking next button while nextButtonEnabled ist set to false', async () => {
    createComponent({ nextButtonEnabled: false });

    await nextButton.trigger('click');

    expect(wrapper.emitted().next).toBe(undefined);
  });
});
