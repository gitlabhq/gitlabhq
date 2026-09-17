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
  });
});
