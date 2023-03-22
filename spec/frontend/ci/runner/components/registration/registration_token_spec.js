import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RegistrationToken from '~/ci/runner/components/registration/registration_token.vue';
import InputCopyToggleVisibility from '~/vue_shared/components/form/input_copy_toggle_visibility.vue';
import { mockRegistrationToken } from '../../mock_data';

describe('RegistrationToken', () => {
  let wrapper;
  let showToast;

  Vue.use(GlToast);

  const findInputCopyToggleVisibility = () => wrapper.findComponent(InputCopyToggleVisibility);

  const createComponent = ({ props = {}, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(RegistrationToken, {
      propsData: {
        value: mockRegistrationToken,
        inputId: 'token-value',
        ...props,
      },
    });

    showToast = wrapper.vm.$toast ? jest.spyOn(wrapper.vm.$toast, 'show') : null;
  };

  it('Displays value and copy button', () => {
    createComponent();

    expect(findInputCopyToggleVisibility().props('value')).toBe(mockRegistrationToken);
    expect(findInputCopyToggleVisibility().props('copyButtonTitle')).toBe(
      'Copy registration token',
    );
  });

  // Component integration test to ensure secure masking
  it('Displays masked value by default', () => {
    const mockToken = '0123456789';
    const maskToken = '**********';

    createComponent({
      props: {
        value: mockToken,
      },
      mountFn: mountExtended,
    });

    expect(wrapper.find('input').element.value).toBe(maskToken);
  });

  describe('When the copy to clipboard button is clicked', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows a copied message', () => {
      findInputCopyToggleVisibility().vm.$emit('copy');

      expect(showToast).toHaveBeenCalledTimes(1);
      expect(showToast).toHaveBeenCalledWith('Registration token copied!');
    });
  });
});
