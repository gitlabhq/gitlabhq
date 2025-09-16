import { shallowMount } from '@vue/test-utils';
import { GlIntersectionObserver } from '@gitlab/ui';
import InboundTokenAccess from '~/token_access/components/inbound_token_access.vue';
import TokenAccessApp from '~/token_access/components/token_access_app.vue';
import TokenPermissions from '~/token_access/components/token_permissions.vue';

describe('TokenAccessApp component', () => {
  let wrapper;

  const findInboundTokenAccess = () => wrapper.findComponent(InboundTokenAccess);
  const findTokenPermissions = () => wrapper.findComponent(TokenPermissions);
  const findIntersectionObserver = () => wrapper.findComponent(GlIntersectionObserver);

  const createComponent = () => {
    wrapper = shallowMount(TokenAccessApp, {});
  };

  const emitIntersectionObserverUpdate = (isIntersecting) => {
    findIntersectionObserver().vm.$emit('update', { isIntersecting });
  };

  describe.each`
    phrase                         | action                                         | expected
    ${'on page load'}              | ${() => {}}                                    | ${false}
    ${'when section is expanded'}  | ${() => emitIntersectionObserverUpdate(true)}  | ${true}
    ${'when section is collapsed'} | ${() => emitIntersectionObserverUpdate(false)} | ${false}
  `('$phrase', ({ action, expected }) => {
    beforeEach(() => {
      createComponent();
      action();
    });

    it('renders intersection observer', () => {
      expect(findIntersectionObserver().exists()).toBe(true);
    });

    it('renders/does not render the inbound token access component', () => {
      expect(findInboundTokenAccess().exists()).toBe(expected);
    });

    it('renders/does not render the token permissions component', () => {
      expect(findTokenPermissions().exists()).toBe(expected);
    });
  });
});
