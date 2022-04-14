import { GlToast } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RegistrationToken from '~/runner/components/registration/registration_token.vue';
import InputCopyToggleVisibility from '~/vue_shared/components/form/input_copy_toggle_visibility.vue';

const mockToken = '01234567890';
const mockMasked = '***********';

describe('RegistrationToken', () => {
  let wrapper;
  let showToast;

  const findInputCopyToggleVisibility = () => wrapper.findComponent(InputCopyToggleVisibility);

  const vueWithGlToast = () => {
    const localVue = createLocalVue();
    localVue.use(GlToast);
    return localVue;
  };

  const createComponent = ({
    props = {},
    withGlToast = true,
    mountFn = shallowMountExtended,
  } = {}) => {
    const localVue = withGlToast ? vueWithGlToast() : undefined;

    wrapper = mountFn(RegistrationToken, {
      propsData: {
        value: mockToken,
        ...props,
      },
      localVue,
    });

    showToast = wrapper.vm.$toast ? jest.spyOn(wrapper.vm.$toast, 'show') : null;
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays value and copy button', () => {
    createComponent();

    expect(findInputCopyToggleVisibility().props('value')).toBe(mockToken);
    expect(findInputCopyToggleVisibility().props('copyButtonTitle')).toBe(
      'Copy registration token',
    );
  });

  // Component integration test to ensure secure masking
  it('Displays masked value by default', () => {
    createComponent({ mountFn: mountExtended });

    expect(wrapper.find('input').element.value).toBe(mockMasked);
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

    it('does not fail when toast is not defined', () => {
      createComponent({ withGlToast: false });
      findInputCopyToggleVisibility().vm.$emit('copy');

      // This block also tests for unhandled errors
      expect(showToast).toBeNull();
    });
  });
});
