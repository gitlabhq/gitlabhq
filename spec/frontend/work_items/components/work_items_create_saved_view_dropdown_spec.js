import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemsCreateSavedViewDropdown from '~/work_items/components/work_items_create_saved_view_dropdown.vue';
import WorkItemsNewSavedViewModal from '~/work_items/components/work_items_new_saved_view_modal.vue';

import waitForPromises from 'helpers/wait_for_promises';

describe('WorkItemsCreateSavedViewDropdown', () => {
  let wrapper;
  const createComponent = () => {
    wrapper = shallowMountExtended(WorkItemsCreateSavedViewDropdown);
  };
  const findDropdownSelector = () => wrapper.findByTestId('add-saved-view-toggle');
  const findNewSavedViewModal = () => wrapper.findComponent(WorkItemsNewSavedViewModal);

  beforeEach(() => {
    createComponent();
  });

  it('correctly renders the dropdown', () => {
    const items = findDropdownSelector().props('items');
    expect(items[0].text).toBe('New view');
    expect(items[1].text).toBe('Existing view');
  });

  it('opens new saved view modal when "New view" is selected', async () => {
    expect(findNewSavedViewModal().props('show')).toBe(false);

    findDropdownSelector().props('items')[0].action();
    await waitForPromises();

    expect(findNewSavedViewModal().props('show')).toBe(true);
  });
});
