import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupActionsApp from '~/groups/show/actions/components/app.vue';
import GroupListItemActions from '~/vue_shared/components/groups_list/group_list_item_actions.vue';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import {
  ACTION_DELETE,
  ACTION_DELETE_IMMEDIATELY,
  ACTION_LEAVE,
} from '~/vue_shared/components/list_actions/constants';
import setWindowLocation from 'helpers/set_window_location_helper';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
  visitUrlWithAlerts: jest.fn(),
}));

describe('GroupActionsApp', () => {
  let wrapper;

  const mockGroup = {
    id: 1,
    name: 'Test Group',
    fullName: 'Test Group',
    fullPath: 'test-group',
  };

  const defaultProps = {
    group: mockGroup,
    dashboardPath: '/dashboard/groups',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(GroupActionsApp, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findGroupListItemActions = () => wrapper.findComponent(GroupListItemActions);

  beforeEach(() => {
    createComponent();
  });

  it('renders GroupListItemActions component', () => {
    expect(findGroupListItemActions().exists()).toBe(true);
  });

  it('passes group prop to GroupListItemActions', () => {
    expect(findGroupListItemActions().props('group')).toEqual(mockGroup);
  });

  describe('when action event is emitted', () => {
    describe('when action is ACTION_DELETE', () => {
      it('redirects to dashboardPath with scheduled deletion alert', () => {
        findGroupListItemActions().vm.$emit('action', ACTION_DELETE);

        expect(visitUrlWithAlerts).toHaveBeenCalledWith('http://test.host/dashboard/groups', [
          {
            id: 'namespace-delete-scheduled-success',
            message: 'Test Group moved to pending deletion.',
            variant: 'info',
          },
        ]);
      });
    });

    describe('when action is ACTION_DELETE_IMMEDIATELY', () => {
      it('redirects to dashboardPath', () => {
        findGroupListItemActions().vm.$emit('action', ACTION_DELETE_IMMEDIATELY);

        expect(visitUrlWithAlerts).toHaveBeenCalledWith('http://test.host/dashboard/groups', [
          {
            id: 'namespace-delete-success',
            message: 'Test Group is being deleted.',
            variant: 'info',
          },
        ]);
      });
    });

    describe('when action is ACTION_LEAVE', () => {
      it('redirects to dashboardPath with alerts', () => {
        findGroupListItemActions().vm.$emit('action', ACTION_LEAVE);

        expect(visitUrlWithAlerts).toHaveBeenCalledWith('http://test.host/dashboard/groups', [
          {
            id: 'namespace-leave-success',
            message: 'You left the "Test Group" group.',
            variant: 'info',
          },
        ]);
      });
    });

    describe('when action is any other action', () => {
      it('redirects to the fullpath', () => {
        setWindowLocation('?leave=1&search=text');

        findGroupListItemActions().vm.$emit('action', 'some-other-action');

        expect(visitUrlWithAlerts).toHaveBeenCalledWith(
          `http://test.host/${mockGroup.fullPath}`,
          [],
        );
      });
    });
  });
});
