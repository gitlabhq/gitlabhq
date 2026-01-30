import { GlDisclosureDropdown, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemsSavedViewSelector from '~/work_items/list/components/work_items_saved_view_selector.vue';
import { CREATED_DESC } from '~/work_items/list/constants';

const mockSavedView = {
  __typename: 'SavedView',
  id: '1',
  name: 'My View',
  userPermissions: {
    updateSavedView: true,
  },
};
describe('WorkItemsSavedViewSelector', () => {
  let wrapper;

  const createComponent = ({
    routeMock = {
      params: { view_id: undefined },
    },
    savedView = mockSavedView,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemsSavedViewSelector, {
      propsData: {
        savedView,
        fullPath: 'test-project-path',
        sortKey: CREATED_DESC,
      },
      mocks: {
        $route: routeMock,
      },
    });
  };

  const findSelector = () => wrapper.findByTestId('saved-view-selector');
  const findEditAction = () => wrapper.findByTestId('edit-action');
  const findDuplicateAction = () => wrapper.findByTestId('duplicate-action');
  const findCopyAction = () => wrapper.findByTestId('copy-action');
  const findUnsubscribeAction = () => wrapper.findByTestId('unsubscribe-action');
  const findDeleteAction = () => wrapper.findByTestId('delete-action');
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findButton = () => wrapper.findComponent(GlButton);

  describe('when active', () => {
    beforeEach(() => {
      createComponent({ routeMock: { params: { view_id: '1' } } });
    });

    it('renders a dropdown', () => {
      expect(findDropdown().exists()).toBe(true);
    });

    it('renders the selector and dropdown actions', () => {
      expect(findEditAction().exists()).toBe(true);
      expect(findDuplicateAction().exists()).toBe(true);
      expect(findCopyAction().exists()).toBe(true);
      expect(findUnsubscribeAction().exists()).toBe(true);
      expect(findDeleteAction().exists()).toBe(true);
    });

    it('shows the caret when active and applies appropriate styles', () => {
      expect(findSelector().classes()).toContain('saved-view-selector-active');
      expect(findSelector().props('noCaret')).toBe(false);
    });

    it('does not render edit action when there is no permission', () => {
      createComponent({
        routeMock: { params: { view_id: '1' } },
        savedView: {
          ...mockSavedView,
          userPermissions: {
            updateSavedView: false,
          },
        },
      });

      expect(findEditAction().exists()).toBe(false);
    });
  });

  describe('when not active', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a button as a link with correct value', () => {
      const button = findButton();
      expect(button.exists()).toBe(true);
      expect(button.props('to')).toEqual({ name: 'savedView', params: { view_id: '1' } });
    });
  });
});
