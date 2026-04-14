import { GlTruncate } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DashboardsListNameCell from '~/vue_shared/components/dashboards_list/dashboards_list_name_cell.vue';

const mockDashboard = {
  name: 'Built in dashboard',
  description: 'Built in dashboard description',
  isStarred: true,
  dashboardUrl: '/fake/link/to/share',
};

describe('DashboardsListNameCell', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const findDashboardLink = () => wrapper.findByTestId('dashboard-redirect-link');
  const findStarIcon = () => wrapper.findByTestId('dashboard-star-icon');
  const findDescription = () => wrapper.findComponent(GlTruncate);

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

    it('renders the description', () => {
      expect(findDescription().props('text')).toBe(mockDashboard.description);
    });

    it('renders the star icon', () => {
      expect(findStarIcon().props('icon')).toBe('star');
      expect(findStarIcon().attributes('title')).toBe('Remove from favorites');
    });
  });

  describe('with isStarred=false dashboard', () => {
    beforeEach(() => {
      createWrapper({ isStarred: false });
    });

    it('renders the star icon', () => {
      expect(findStarIcon().props('icon')).toBe('star-o');
      expect(findStarIcon().attributes('title')).toBe('Add to favorites');
    });
  });
});
