import { GlForm, GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemsNewSavedViewModal from '~/work_items/components/work_items_new_saved_view_modal.vue';

import waitForPromises from 'helpers/wait_for_promises';

describe('WorkItemsNewSavedViewModal', () => {
  let wrapper;
  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(WorkItemsNewSavedViewModal, {
      propsData: {
        show: true,
        ...props,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findForm = () => wrapper.findComponent(GlForm);
  const findTitleInput = () => wrapper.find('#saved-view-title');
  const findDescriptionInput = () => wrapper.find('#saved-view-description');
  const findVisibilityInputs = () => wrapper.findByTestId('saved-view-visibility');
  const findCreateButton = () => wrapper.findByTestId('create-view-button');

  beforeEach(() => {
    createComponent();
  });

  it('correctly renders the modal and the form', () => {
    expect(findForm().exists()).toBe(true);
    expect(findTitleInput().exists()).toBe(true);
    expect(findDescriptionInput().exists()).toBe(true);
    expect(findVisibilityInputs().exists()).toBe(true);
  });

  it('autofocuses the title input when the modal is shown', async () => {
    findTitleInput().element.focus = jest.fn();

    findModal().vm.$emit('shown');
    await waitForPromises();

    expect(findTitleInput().element.focus).toHaveBeenCalled();
  });

  it('disables the submit button if invalid title is provided', async () => {
    findTitleInput().vm.$emit('input', '');

    findForm().vm.$emit('submit', {
      preventDefault: jest.fn(),
    });
    await waitForPromises();

    expect(findCreateButton().props('disabled')).toBe(true);
  });

  it('creates new saved view and hides modal when submitting a form', async () => {
    findTitleInput().vm.$emit('input', 'view title');

    findForm().vm.$emit('submit', {
      preventDefault: jest.fn(),
    });

    await waitForPromises();

    expect(wrapper.emitted('hide')).toEqual([[false]]);
    expect(findModal().exists()).toBe(true);
  });
});
