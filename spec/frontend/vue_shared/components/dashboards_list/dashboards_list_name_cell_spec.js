import { GlTruncate } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DashboardsListNameCell from '~/vue_shared/components/dashboards_list/dashboards_list_name_cell.vue';

const mockDashboard = {
  name: 'Built in dashboard',
  isStarred: true,
  dashboardUrl: '/fake/link/to/share',
};

describe('DashboardsListNameCell', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const findDashboardLink = () => wrapper.findByTestId('dashboard-redirect-link');
  const findStarIcon = () => wrapper.findComponentByTestId('dashboard-star-icon');
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

    it('does not render the star icon', () => {
      expect(findStarIcon().exists()).toBe(false);
    });

    it('does not render the description', () => {
      expect(findDescription().exists()).toBe(false);
    });
  });

  describe('with a description', () => {
    beforeEach(() => {
      createWrapper({ description: 'Built in dashboard description' });
    });

    it('renders the description', () => {
      expect(findDescription().props('text')).toBe('Built in dashboard description');
    });
  });

  describe('with withStars=true', () => {
    it('renders the starred icon when the dashboard is starred', () => {
      createWrapper({ withStars: true });

      expect(findStarIcon().props('icon')).toBe('star');
      expect(findStarIcon().attributes('title')).toBe('Remove from favorites');
    });

    it('renders the unstarred icon when the dashboard is not starred', () => {
      createWrapper({ withStars: true, isStarred: false });

      expect(findStarIcon().props('icon')).toBe('star-o');
      expect(findStarIcon().attributes('title')).toBe('Add to favorites');
    });
  });
});
