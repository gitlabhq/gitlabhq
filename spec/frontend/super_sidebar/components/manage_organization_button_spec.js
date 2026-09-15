import { GlNavItem } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ManageOrganizationButton from '~/super_sidebar/components/manage_organization_button.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

describe('ManageOrganizationButton', () => {
  let wrapper;

  const href = '/o/my-org/admin';

  const createComponent = (provide = {}) => {
    wrapper = mountExtended(ManageOrganizationButton, {
      propsData: { href },
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

    it('renders the admin icon', () => {
      expect(findNavItem().props('icon')).toBe('admin');
    });

    it('links to the provided href', () => {
      expect(findNavItem().attributes('href')).toBe(href);
    });

    it('displays the text', () => {
      expect(findNavItem().text()).toBe('Manage organization');
    });

    it('does not show a tooltip', () => {
      const tooltip = getBinding(findNavItem().element, 'gl-tooltip');

      expect(tooltip.value).toBe('');
    });
  });

  describe('when sidebar is icon only', () => {
    beforeEach(() => {
      createComponent({ isIconOnly: true });
    });

    it('renders as icon only with an aria-label', () => {
      expect(findNavItem().props('isIconOnly')).toBe(true);
      expect(findNavItem().attributes('aria-label')).toBe('Manage organization');
    });

    it('shows a tooltip with the text', () => {
      const tooltip = getBinding(findNavItem().element, 'gl-tooltip');

      expect(tooltip.value).toBe('Manage organization');
    });
  });
});
