import { GlButton, GlTooltip } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import CreateTokenButton from '~/clusters/agents/components/create_token_button.vue';
import { CREATE_TOKEN_MODAL } from '~/clusters/agents/constants';

describe('CreateTokenButton', () => {
  let wrapper;

  const defaultProvide = {
    canAdminCluster: true,
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const findTooltip = () => wrapper.findComponent(GlTooltip);

  const createWrapper = ({ provideData = {} } = {}) => {
    wrapper = shallowMountExtended(CreateTokenButton, {
      provide: {
        ...defaultProvide,
        ...provideData,
      },
      directives: {
        GlModalDirective: createMockDirective('gl-modal-directive'),
      },
      stubs: {
        GlTooltip,
      },
    });
  };

  describe('when user can create token', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('displays create agent token button', () => {
      expect(findButton().text()).toBe('Create token');
    });

    it('displays create agent token button as not disabled', () => {
      expect(findButton().attributes('disabled')).toBeUndefined();
    });

    it('triggers the modal', () => {
      const binding = getBinding(findButton().element, 'gl-modal-directive');

      expect(binding.value).toBe(CREATE_TOKEN_MODAL);
    });
  });

  describe('when user cannot create token', () => {
    beforeEach(() => {
      createWrapper({ provideData: { canAdminCluster: false } });
    });

    it('disabled the button', () => {
      expect(findButton().attributes('disabled')).toBeDefined();
    });

    it('shows a disabled tooltip', () => {
      expect(findTooltip().attributes('title')).toBe(
        'Requires a Maintainer or greater role to perform these actions',
      );
    });
  });
});
