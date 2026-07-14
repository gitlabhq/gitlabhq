import { GlNavItem } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import IconOnlyToggle from '~/super_sidebar/components/icon_only_toggle.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

describe('IconOnlyToggle', () => {
  let wrapper;

  const createComponent = (provide = {}) => {
    wrapper = mountExtended(IconOnlyToggle, {
      provide: {
        isIconOnly: false,
        ...provide,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findNavItem = () => wrapper.findComponent(GlNavItem);

  describe('when sidebar is expanded', () => {
    beforeEach(() => {
      createComponent({ isIconOnly: false });
    });

    it('renders button with correct icon', () => {
      expect(findNavItem().props('icon')).toBe('collapse-left');
    });

    it('displays shrink text', () => {
      expect(findNavItem().text()).toBe('Collapse sidebar');
    });

    it('does not show tooltip', () => {
      expect(findNavItem().attributes('title')).toBeUndefined();
    });
  });

  describe('when sidebar is collapsed (icon only)', () => {
    beforeEach(() => {
      createComponent({ isIconOnly: true });
    });

    it('renders button with correct icon', () => {
      expect(findNavItem().props('icon')).toBe('collapse-right');
    });

    it('does not display text content', () => {
      expect(findNavItem().attributes('aria-label')).toBe('Expand sidebar');
      expect(findNavItem().props('isIconOnly')).toBe(true);
    });

    it('shows tooltip with expand text', () => {
      const buttonTooltipDirective = getBinding(findNavItem().element, 'gl-tooltip');

      expect(buttonTooltipDirective.value).toBe('Expand sidebar');
    });
  });

  describe('interactions', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits toggle event when clicked', async () => {
      await findNavItem().vm.$emit('click');

      expect(wrapper.emitted('toggle')).toHaveLength(1);
    });
  });
});
