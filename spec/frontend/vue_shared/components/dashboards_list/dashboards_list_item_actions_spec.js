import { GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DashboardsListItemActions from '~/vue_shared/components/dashboards_list/dashboards_list_item_actions.vue';

describe('DashboardsListItemActions (CE)', () => {
  let wrapper;

  const defaultProps = {
    actionLabel: 'Actions',
  };

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(DashboardsListItemActions, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findShareAction = () => wrapper.findByText('Share');

  describe('rendering', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the actions dropdown', () => {
      expect(findDropdown().exists()).toBe(true);
    });

    it('renders the dropdown with correct props', () => {
      expect(findDropdown().props()).toMatchObject({
        icon: 'ellipsis_v',
        category: 'tertiary',
        textSrOnly: true,
        noCaret: true,
      });
    });

    it('renders the Share action', () => {
      expect(findShareAction().exists()).toBe(true);
    });
  });

  describe('tooltip', () => {
    beforeEach(() => {
      createWrapper({ actionLabel: 'More options' });
    });

    it('renders with correct tooltip title', () => {
      expect(findDropdown().attributes('title')).toBe('More options');
    });
  });
});
