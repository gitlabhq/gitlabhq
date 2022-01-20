import { nextTick } from 'vue';
import { GlToast } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RegistrationToken from '~/runner/components/registration/registration_token.vue';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';

const mockToken = '01234567890';
const mockMasked = '***********';

describe('RegistrationToken', () => {
  let wrapper;
  let stopPropagation;
  let showToast;

  const findToggleMaskButton = () => wrapper.findByTestId('toggle-masked');
  const findCopyButton = () => wrapper.findComponent(ModalCopyButton);

  const vueWithGlToast = () => {
    const localVue = createLocalVue();
    localVue.use(GlToast);
    return localVue;
  };

  const createComponent = ({ props = {}, withGlToast = true } = {}) => {
    const localVue = withGlToast ? vueWithGlToast() : undefined;

    wrapper = shallowMountExtended(RegistrationToken, {
      propsData: {
        value: mockToken,
        ...props,
      },
      localVue,
    });

    showToast = wrapper.vm.$toast ? jest.spyOn(wrapper.vm.$toast, 'show') : null;
  };

  beforeEach(() => {
    stopPropagation = jest.fn();

    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays masked value by default', () => {
    expect(wrapper.text()).toBe(mockMasked);
  });

  it('Displays button to reveal token', () => {
    expect(findToggleMaskButton().attributes('aria-label')).toBe('Click to reveal');
  });

  it('Can copy the original token value', () => {
    expect(findCopyButton().props('text')).toBe(mockToken);
  });

  describe('When the reveal icon is clicked', () => {
    beforeEach(() => {
      findToggleMaskButton().vm.$emit('click', { stopPropagation });
    });

    it('Click event is not propagated', async () => {
      expect(stopPropagation).toHaveBeenCalledTimes(1);
    });

    it('Displays the actual value', () => {
      expect(wrapper.text()).toBe(mockToken);
    });

    it('Can copy the original token value', () => {
      expect(findCopyButton().props('text')).toBe(mockToken);
    });

    it('Displays button to mask token', () => {
      expect(findToggleMaskButton().attributes('aria-label')).toBe('Click to hide');
    });

    it('When user clicks again, displays masked value', async () => {
      findToggleMaskButton().vm.$emit('click', { stopPropagation });
      await nextTick();

      expect(wrapper.text()).toBe(mockMasked);
      expect(findToggleMaskButton().attributes('aria-label')).toBe('Click to reveal');
    });
  });

  describe('When the copy to clipboard button is clicked', () => {
    it('shows a copied message', () => {
      findCopyButton().vm.$emit('success');

      expect(showToast).toHaveBeenCalledTimes(1);
      expect(showToast).toHaveBeenCalledWith('Registration token copied!');
    });

    it('does not fail when toast is not defined', () => {
      createComponent({ withGlToast: false });
      findCopyButton().vm.$emit('success');

      // This block also tests for unhandled errors
      expect(showToast).toBeNull();
    });
  });
});
