import { GlNavItem } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ManageOrganizationButton from '~/super_sidebar/components/manage_organization_button.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

describe('ManageOrganizationButton', () => {
  let wrapper;

  const href = '/o/my-org/admin';

  const createComponent = ({ provide = {}, propsData = {} } = {}) => {
    wrapper = mountExtended(ManageOrganizationButton, {
      propsData: { href, ...propsData },
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
      createComponent({ provide: { isIconOnly: false } });
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

  describe('when isExit is true', () => {
    beforeEach(() => {
      createComponent({ propsData: { isExit: true } });
    });

    it('renders the leave icon', () => {
      expect(findNavItem().props('icon')).toBe('go-back');
    });

    it('displays the exit text', () => {
      expect(findNavItem().text()).toBe('Back to organization');
    });

    it('uses the exit text as the aria-label', () => {
      expect(findNavItem().attributes('aria-label')).toBe('Back to organization');
    });
  });

  describe('when sidebar is icon only', () => {
    beforeEach(() => {
      createComponent({ provide: { isIconOnly: true } });
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
