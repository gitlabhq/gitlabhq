import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemsCreateSavedViewDropdown from '~/work_items/list/components/work_items_create_saved_view_dropdown.vue';
import WorkItemsNewSavedViewModal from '~/work_items/list/components/work_items_new_saved_view_modal.vue';
import WorkItemsExistingSavedViewsModal from '~/work_items/list/components/work_items_existing_saved_views_modal.vue';
import { CREATED_DESC } from '~/work_items/list/constants';
import waitForPromises from 'helpers/wait_for_promises';

describe('WorkItemsCreateSavedViewDropdown', () => {
  let wrapper;
  const createComponent = () => {
    wrapper = shallowMountExtended(WorkItemsCreateSavedViewDropdown, {
      propsData: {
        fullPath: 'test-project-path',
        sortKey: CREATED_DESC,
      },
    });
  };
  const findDropdownSelector = () => wrapper.findByTestId('add-saved-view-toggle');
  const findNewSavedViewModal = () => wrapper.findComponent(WorkItemsNewSavedViewModal);
  const findExistingSavedViewsModal = () => wrapper.findComponent(WorkItemsExistingSavedViewsModal);

  beforeEach(() => {
    createComponent();
  });

  it('correctly renders the dropdown', () => {
    const items = findDropdownSelector().props('items');
    expect(items[0].text).toBe('New view');
    expect(items[1].text).toBe('Browse views');
  });

  it.each`
    label              | itemIndex | findModal
    ${'New view'}      | ${0}      | ${() => findNewSavedViewModal()}
    ${'Existing view'} | ${1}      | ${() => findExistingSavedViewsModal()}
  `('opens $label modal when "$label" is selected', async ({ itemIndex, findModal }) => {
    expect(findModal().props('show')).toBe(false);

    findDropdownSelector().props('items')[itemIndex].action();
    await waitForPromises();

    expect(findModal().props('show')).toBe(true);
  });
});
