import { GlAlert } from '@gitlab/ui';
import { createTestingPinia } from '@pinia/testing';
import Vue from 'vue';
import { PiniaVuePlugin } from 'pinia';
import AccessToken from '~/vue_shared/access_tokens/components/access_token.vue';
import { useAccessTokens } from '~/vue_shared/access_tokens/stores/access_tokens';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import InputCopyToggleVisibility from '~/vue_shared/components/input_copy_toggle_visibility/input_copy_toggle_visibility.vue';

Vue.use(PiniaVuePlugin);

describe('AccessToken', () => {
  let wrapper;

  const token = 'my-token';

  const pinia = createTestingPinia();
  const store = useAccessTokens();

  const createComponent = () => {
    wrapper = shallowMountExtended(AccessToken, {
      pinia,
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findInputCopyToggleVisibility = () => wrapper.findComponent(InputCopyToggleVisibility);

  beforeEach(() => {
    store.token = token;
    createComponent();
  });

  it('renders the alert', () => {
    expect(findAlert().exists()).toBe(true);
    expect(findInputCopyToggleVisibility().props()).toMatchObject({
      copyButtonTitle: 'Copy token',
      formInputGroupProps: {
        'data-testid': 'access-token-field',
        id: 'access-token-field',
        name: 'access-token-field',
      },
      initialVisibility: false,
      readonly: true,
      showCopyButton: true,
      showToggleVisibilityButton: true,
      size: 'lg',
      value: token,
    });
  });

  it('nullifies token if alert is dismissed', () => {
    findAlert().vm.$emit('dismiss');
    expect(store.setToken).toHaveBeenCalledWith(null);
  });
});
