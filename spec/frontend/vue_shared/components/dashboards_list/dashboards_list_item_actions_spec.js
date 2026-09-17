import { GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import DashboardsListItemActions from '~/vue_shared/components/dashboards_list/dashboards_list_item_actions.vue';

describe('DashboardsListItemActions (CE)', () => {
  let wrapper;

  const mockToastShow = jest.fn();

  const defaultProps = {
    actionLabel: 'More actions for My dashboard',
    dashboardUrl: '/dashboards/my-dashboard',
  };

  const createWrapper = (props = {}, mountFn = shallowMountExtended) => {
    wrapper = mountFn(DashboardsListItemActions, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      mocks: {
        $toast: { show: mockToastShow },
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findOpenAction = () => wrapper.findComponentByTestId('dashboard-open-action');
  const findCopyLinkAction = () => wrapper.findComponentByTestId('dashboard-copy-link-action');
  const findDeleteAction = () => wrapper.findComponentByTestId('dashboard-delete-action');

  describe('rendering', () => {
    beforeEach(() => {
      createWrapper({}, mountExtended);
    });

    it('renders the actions dropdown with the accessible name as sr-only toggle text', () => {
      expect(findDropdown().props()).toMatchObject({
        icon: 'ellipsis_v',
        category: 'tertiary',
        textSrOnly: true,
        noCaret: true,
        toggleText: 'More actions for My dashboard',
      });
    });

    it('renders only the Open dashboard and Copy link actions', () => {
      expect(findOpenAction().text()).toBe('Open dashboard');
      expect(findCopyLinkAction().text()).toBe('Copy link');
      expect(findDeleteAction().exists()).toBe(false);
    });

    it('renders an icon on each action', () => {
      expect(findOpenAction().props('icon')).toBe('dashboard');
      expect(findCopyLinkAction().props('icon')).toBe('link');
    });
  });

  describe('open dashboard action', () => {
    beforeEach(() => {
      createWrapper({}, mountExtended);
    });

    it('renders a link to the dashboard URL', () => {
      expect(findOpenAction().find('a').attributes('href')).toBe('/dashboards/my-dashboard');
    });
  });

  describe('copy link action', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('copies the absolute dashboard URL to the clipboard', () => {
      expect(findCopyLinkAction().attributes('data-clipboard-text')).toBe(
        'http://test.host/dashboards/my-dashboard',
      );
    });

    it('shows a toast when clicked', () => {
      findCopyLinkAction().vm.$emit('action');

      expect(mockToastShow).toHaveBeenCalledWith('Link copied to clipboard.');
    });
  });
});
