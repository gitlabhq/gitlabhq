import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemsSavedViewSelector from '~/work_items/components/work_items_saved_view_selector.vue';

const mockSavedView = {
  __typename: 'SavedView',
  id: '1',
  name: 'My View',
};
describe('WorkItemsSavedViewSelector', () => {
  let wrapper;

  const createComponent = (routeMock = { params: { view_id: undefined } }) => {
    wrapper = shallowMountExtended(WorkItemsSavedViewSelector, {
      propsData: {
        savedView: mockSavedView,
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

  beforeEach(() => {
    createComponent();
  });

  it('renders the selector and dropdown actions', () => {
    expect(findEditAction().exists()).toBe(true);
    expect(findDuplicateAction().exists()).toBe(true);
    expect(findCopyAction().exists()).toBe(true);
    expect(findUnsubscribeAction().exists()).toBe(true);
    expect(findDeleteAction().exists()).toBe(true);
  });

  it('does not show the caret when inactive', () => {
    expect(findSelector().classes()).not.toContain('saved-view-selector-active');
    expect(findSelector().props('noCaret')).toBe(true);
  });

  it('shows the caret when active and applies appropriate styles', () => {
    createComponent({ params: { view_id: '1' } });

    expect(findSelector().classes()).toContain('saved-view-selector-active');
    expect(findSelector().props('noCaret')).toBe(false);
  });
});
