import { shallowMount } from '@vue/test-utils';
import OutboundTokenAccess from '~/token_access/components/outbound_token_access.vue';
import InboundTokenAccess from '~/token_access/components/inbound_token_access.vue';
import OptInJwt from '~/token_access/components/opt_in_jwt.vue';
import TokenAccessApp from '~/token_access/components/token_access_app.vue';

describe('TokenAccessApp component', () => {
  let wrapper;

  const findOutboundTokenAccess = () => wrapper.findComponent(OutboundTokenAccess);
  const findInboundTokenAccess = () => wrapper.findComponent(InboundTokenAccess);
  const findOptInJwt = () => wrapper.findComponent(OptInJwt);

  const createComponent = () => {
    wrapper = shallowMount(TokenAccessApp);
  };

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the opt in jwt component', () => {
      expect(findOptInJwt().exists()).toBe(true);
    });

    it('renders the outbound token access component', () => {
      expect(findOutboundTokenAccess().exists()).toBe(true);
    });

    it('renders the inbound token access component', () => {
      createComponent(true);

      expect(findInboundTokenAccess().exists()).toBe(true);
    });
  });
});
