import { shallowMount } from '@vue/test-utils';
import InboundTokenAccess from '~/token_access/components/inbound_token_access.vue';
import OutboundTokenAccess from '~/token_access/components/outbound_token_access.vue';
import TokenAccessApp from '~/token_access/components/token_access_app.vue';
import TokenPermissions from '~/token_access/components/token_permissions.vue';

describe('TokenAccessApp component', () => {
  let wrapper;

  const findInboundTokenAccess = () => wrapper.findComponent(InboundTokenAccess);
  const findOutboundTokenAccess = () => wrapper.findComponent(OutboundTokenAccess);
  const findTokenPermissions = () => wrapper.findComponent(TokenPermissions);

  const createComponent = ({ allowPushRepositoryForJobToken = true } = {}) => {
    wrapper = shallowMount(TokenAccessApp, {
      provide: {
        glFeatures: {
          allowPushRepositoryForJobToken,
        },
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the outbound token access component', () => {
      expect(findOutboundTokenAccess().exists()).toBe(true);
    });

    it('renders the inbound token access component', () => {
      expect(findInboundTokenAccess().exists()).toBe(true);
    });

    it('renders the token permissions component', () => {
      expect(findTokenPermissions().exists()).toBe(true);
    });
  });

  describe('when allowPushRepositoryForJobToken feature flag is disabled', () => {
    beforeEach(() => {
      createComponent({ allowPushRepositoryForJobToken: false });
    });

    it('does not render the token permissions component', () => {
      expect(findTokenPermissions().exists()).toBe(false);
    });
  });
});
