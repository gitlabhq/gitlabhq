import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DashboardsListNameCell from '~/vue_shared/components/dashboards_list/dashboards_list_name_cell.vue';

const mockDashboard = {
  name: 'Built in dashboard',
  dashboardUrl: '/fake/link/to/share',
};

describe('DashboardsListNameCell', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const findDashboardLink = () => wrapper.findByTestId('dashboard-redirect-link');
  const findDescription = () => wrapper.findByTestId('dashboard-description');

  const createWrapper = (props = {}, mountFn = shallowMountExtended) => {
    wrapper = mountFn(DashboardsListNameCell, {
      propsData: {
        ...mockDashboard,
        ...props,
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the name', () => {
      expect(findDashboardLink().text()).toBe(mockDashboard.name);
    });

    it('does not stretch the link, so table rows stay individually clickable', () => {
      expect(findDashboardLink().classes()).not.toContain('gl-stretched-link');
    });

    it('does not render the description', () => {
      expect(findDescription().exists()).toBe(false);
    });
  });

  describe('with a long unbroken name', () => {
    beforeEach(() => {
      createWrapper({
        name: 'a_71_character_unbroken_name_that_would_otherwise_overflow_the_card_yes',
      });
    });

    it('breaks the name anywhere so unbroken strings wrap inside the card', () => {
      expect(findDashboardLink().classes()).toContain('gl-break-anywhere');
    });
  });

  describe('when stretched', () => {
    beforeEach(() => {
      createWrapper({ stretched: true });
    });

    it('stretches the link over the closest positioned ancestor', () => {
      expect(findDashboardLink().classes()).toContain('gl-stretched-link');
    });
  });

  describe('with a description', () => {
    beforeEach(() => {
      createWrapper({ description: 'Built in dashboard description' });
    });

    it('renders the description', () => {
      expect(findDescription().text()).toBe('Built in dashboard description');
    });

    it('clamps the description to two lines instead of truncating mid-word', () => {
      expect(findDescription().classes()).toContain('gl-line-clamp-2');
    });

    it('exposes the full description as a native title so clamped text stays recoverable', () => {
      expect(findDescription().attributes('title')).toBe('Built in dashboard description');
    });

    it('breaks the description anywhere so unbroken strings clamp instead of overflowing', () => {
      expect(findDescription().classes()).toContain('gl-break-anywhere');
    });
  });
});
