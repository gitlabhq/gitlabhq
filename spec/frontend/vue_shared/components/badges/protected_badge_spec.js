import { mount } from '@vue/test-utils';
import protectedBadge from '~/vue_shared/components/badges/protected_badge.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

describe('ProtectedBadge component', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = mount(protectedBadge, {
      propsData: { ...props },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  it('renders the badge', () => {
    createWrapper();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('binds tooltip directive', () => {
    createWrapper();

    const badgeProtectionRuleExistsTooltipBinding = getBinding(wrapper.element, 'gl-tooltip');
    expect(badgeProtectionRuleExistsTooltipBinding).toBeDefined();
  });

  describe('with tooltipText', () => {
    const tooltipText = 'This is resource is protected.';

    it('renders the badge with tooltip', () => {
      createWrapper({ tooltipText });

      expect(wrapper.element.title).toBe(tooltipText);
    });
  });
});
