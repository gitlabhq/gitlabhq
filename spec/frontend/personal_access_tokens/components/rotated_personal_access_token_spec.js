import { GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RotatedPersonalAccessToken from '~/personal_access_tokens/components/rotated_personal_access_token.vue';
import InputCopyToggleVisibility from '~/vue_shared/components/input_copy_toggle_visibility/input_copy_toggle_visibility.vue';

describe('RotatedPersonalAccessToken', () => {
  let wrapper;

  const tokenValue = 'xx';

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(RotatedPersonalAccessToken, {
      propsData: {
        value: tokenValue,
        ...props,
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findInputCopyToggleVisibility = () => wrapper.findComponent(InputCopyToggleVisibility);

  beforeEach(() => {
    createComponent();
  });

  it('renders the success alert', () => {
    expect(findAlert().exists()).toBe(true);
    expect(findAlert().props('variant')).toBe('success');
  });

  it('renders the input copy toggle visibility component', () => {
    expect(findInputCopyToggleVisibility().exists()).toBe(true);

    expect(findInputCopyToggleVisibility().props()).toMatchObject({
      showCopyButton: true,
      value: tokenValue,
      readonly: true,
      size: 'xl',
      formInputGroupProps: {
        'data-testid': 'rotated-personal-access-token-field',
        autocomplete: 'off',
      },
    });

    expect(findInputCopyToggleVisibility().attributes()).toMatchObject({
      'aria-label': 'Your personal access token',
      'label-for': 'rotated-personal-access-token-field',
    });
  });

  it('displays the rotation success message in the description slot', () => {
    expect(wrapper.text()).toContain(
      "Token rotated successfully. Make sure you copy your token - you won't be able to access it again.",
    );
  });

  it('allows the alert to be dismissible', () => {
    expect(findAlert().props('dismissible')).toBe(true);
  });

  it('emits input event with null when alert is dismissed', async () => {
    await findAlert().vm.$emit('dismiss');

    expect(wrapper.emitted('input')).toEqual([[null]]);
  });
});
