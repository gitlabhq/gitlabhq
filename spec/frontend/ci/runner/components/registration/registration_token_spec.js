import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RegistrationToken from '~/ci/runner/components/registration/registration_token.vue';
import InputCopyToggleVisibility from '~/vue_shared/components/input_copy_toggle_visibility/input_copy_toggle_visibility.vue';
import { mockRegistrationToken } from '../../mock_data';

describe('RegistrationToken', () => {
  let wrapper;
  const showToastMock = jest.fn();

  Vue.use(GlToast);

  const findInputCopyToggleVisibility = () => wrapper.findComponent(InputCopyToggleVisibility);

  const createComponent = ({ props = {}, mountFn = shallowMountExtended, ...options } = {}) => {
    wrapper = mountFn(RegistrationToken, {
      propsData: {
        value: mockRegistrationToken,
        inputId: 'token-value',
        ...props,
      },
      ...options,
      mocks: {
        $toast: {
          show: showToastMock,
        },
      },
    });
  };

  it('Displays value and copy button', () => {
    createComponent();

    expect(findInputCopyToggleVisibility().props('value')).toBe(mockRegistrationToken);
    expect(findInputCopyToggleVisibility().props('copyButtonTitle')).toBe(
      'Copy registration token',
    );
  });

  it('Renders readonly input', () => {
    createComponent();

    expect(findInputCopyToggleVisibility().props('readonly')).toBe(true);
  });

  // Component integration test to ensure secure masking
  it('Displays masked value as password input by default', () => {
    const mockToken = '0123456789';

    createComponent({
      props: {
        value: mockToken,
      },
      mountFn: mountExtended,
    });

    expect(wrapper.find('input').classes()).toContain('input-copy-show-disc');
  });

  describe('When the copy to clipboard button is clicked', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows a copied message', () => {
      findInputCopyToggleVisibility().vm.$emit('copy');

      expect(showToastMock).toHaveBeenCalledTimes(1);
      expect(showToastMock).toHaveBeenCalledWith('Registration token copied!');
    });

    it('emits a copy event', () => {
      findInputCopyToggleVisibility().vm.$emit('copy');

      expect(wrapper.emitted('copy')).toHaveLength(1);
    });
  });

  describe('When slots are used', () => {
    const slotName = 'label-description';
    const slotContent = 'Label Description';

    beforeEach(() => {
      createComponent({
        slots: {
          [slotName]: slotContent,
        },
      });
    });

    it('passes slots to the input component', () => {
      expect(findInputCopyToggleVisibility().text()).toBe(slotContent);
    });
  });
});
